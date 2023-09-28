// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MockAxelarGateway} from "../../../contracts/bridge/test/MockAxelarGateway.sol";
import {MockAxelarGasService} from "../../../contracts/bridge/test/MockAxelarGasService.sol";
import {RootERC20Bridge, IRootERC20BridgeEvents, IERC20Metadata} from "../../../contracts/bridge/RootERC20Bridge.sol";
import {RootAxelarBridgeAdaptor, IAxelarBridgeAdaptorEvents} from "../../../contracts/bridge/RootAxelarBridgeAdaptor.sol";
import {Utils} from "../utils.t.sol";

contract RootERC20BridgeIntegrationTest is Test, IRootERC20BridgeEvents, IAxelarBridgeAdaptorEvents, Utils {
    address constant CHILD_BRIDGE = address(3);
    address constant CHILD_BRIDGE_ADAPTOR = address(4);
    string constant CHILD_CHAIN_NAME = "test";
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    ERC20PresetMinterPauser public token;
    RootERC20Bridge public rootBridge;
    RootAxelarBridgeAdaptor public axelarAdaptor;
    MockAxelarGateway public mockAxelarGateway;
    MockAxelarGasService public axelarGasService;

    function setUp() public {
        (token, rootBridge, axelarAdaptor, mockAxelarGateway, axelarGasService) =
            integrationSetup(CHILD_BRIDGE, CHILD_BRIDGE_ADAPTOR, CHILD_CHAIN_NAME);
    }

    /**
     * @dev A future test will assert that the computed childToken is the same as what gets deployed on L2.
     *      This test uses the same code as the mapToken function does to calculate this address, so we can
     *      not consider it sufficient.
     */
    function test_mapToken() public {
        uint256 mapTokenFee = 300;
        address childToken =
            Clones.predictDeterministicAddress(address(token), keccak256(abi.encodePacked(token)), CHILD_BRIDGE);

        bytes memory payload = abi.encode(MAP_TOKEN_SIG, address(token), token.name(), token.symbol(), token.decimals());
        vm.expectEmit(true, true, true, false, address(axelarAdaptor));
        emit MapTokenAxelarMessage(CHILD_CHAIN_NAME, Strings.toHexString(CHILD_BRIDGE_ADAPTOR), payload);

        vm.expectEmit(true, true, false, false, address(rootBridge));
        emit TokenMapped(address(token), childToken);

        // Instead of using expectCalls, we could use expectEmit in combination with mock contracts emitting events.
        // expectCalls requires less boilerplate and is less dependant on mock code.
        vm.expectCall(
            address(axelarAdaptor),
            mapTokenFee,
            abi.encodeWithSelector(
                axelarAdaptor.mapToken.selector, address(token), token.name(), token.symbol(), token.decimals()
            )
        );

        // These are calls that the axelarAdaptor should make.
        vm.expectCall(
            address(axelarGasService),
            mapTokenFee,
            abi.encodeWithSelector(
                axelarGasService.payNativeGasForContractCall.selector,
                address(axelarAdaptor),
                CHILD_CHAIN_NAME,
                Strings.toHexString(CHILD_BRIDGE_ADAPTOR),
                payload,
                address(rootBridge)
            )
        );

        vm.expectCall(
            address(mockAxelarGateway),
            0,
            abi.encodeWithSelector(
                mockAxelarGateway.callContract.selector,
                CHILD_CHAIN_NAME,
                Strings.toHexString(CHILD_BRIDGE_ADAPTOR),
                payload
            )
        );

        rootBridge.mapToken{value: mapTokenFee}(token);

        assertEq(rootBridge.rootTokenToChildToken(address(token)), childToken);
    }
}
