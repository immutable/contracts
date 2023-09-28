// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MockAxelarGateway} from "../../../contracts/bridge/test/MockAxelarGateway.sol";
import {MockAxelarGasService} from "../../../contracts/bridge/test/MockAxelarGasService.sol";
import {RootAxelarBridgeAdaptor, IAxelarBridgeAdaptorEvents, IAxelarBridgeAdaptorErrors} from "../../../contracts/bridge/RootAxelarBridgeAdaptor.sol";

contract RootAxelarBridgeAdaptorTest is Test, IAxelarBridgeAdaptorEvents, IAxelarBridgeAdaptorErrors {
    address constant CHILD_BRIDGE = address(3);
    address constant CHILD_BRIDGE_ADAPTOR = address(4);
    string constant CHILD_CHAIN_NAME = "test";
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    ERC20PresetMinterPauser public token;
    RootAxelarBridgeAdaptor public axelarAdaptor;
    MockAxelarGateway public mockAxelarGateway;
    MockAxelarGasService public axelarGasService;

    function setUp() public {
        token = new ERC20PresetMinterPauser("Test", "TST");
        mockAxelarGateway = new MockAxelarGateway();
        axelarGasService = new MockAxelarGasService();

        axelarAdaptor = new RootAxelarBridgeAdaptor(
            address(this), // set rootBridge to address(this) for unit testing
            CHILD_BRIDGE_ADAPTOR,
            CHILD_CHAIN_NAME,
            address(mockAxelarGateway),
            address(axelarGasService)
        );
    }

    function test_Constructor() public {
        assertEq(axelarAdaptor.ROOT_BRIDGE(), address(this));
        assertEq(axelarAdaptor.childBridgeAdaptor(), Strings.toHexString(CHILD_BRIDGE_ADAPTOR));
        assertEq(axelarAdaptor.childChain(), CHILD_CHAIN_NAME);
        assertEq(address(axelarAdaptor.AXELAR_GATEWAY()), address(mockAxelarGateway));
        assertEq(address(axelarAdaptor.GAS_SERVICE()), address(axelarGasService));
    }

    function test_RevertsWhen_ConstructorGivenZeroAddress() public {
        vm.expectRevert(ZeroAddresses.selector);
        new RootAxelarBridgeAdaptor(
            address(0),
            CHILD_BRIDGE_ADAPTOR,
            CHILD_CHAIN_NAME,
            address(mockAxelarGateway),
            address(axelarGasService)
        );
    }

    function test_RevertsWhen_ConstructorGivenEmptyChildChainName() public {
        vm.expectRevert(InvalidChildChain.selector);
        new RootAxelarBridgeAdaptor(
            address(this),
            CHILD_BRIDGE_ADAPTOR,
            "",
            address(mockAxelarGateway),
            address(axelarGasService)
        );
    }

    /// @dev For this unit test we just want to make sure the correct functions are called on the Axelar Gateway and Gas Service.
    function test_mapToken() public {
        bytes memory payload = abi.encode(MAP_TOKEN_SIG, address(token), token.name(), token.symbol(), token.decimals());
        uint256 callValue = 300;

        vm.expectCall(
            address(axelarGasService),
            callValue,
            abi.encodeWithSelector(
                axelarGasService.payNativeGasForContractCall.selector,
                address(axelarAdaptor),
                CHILD_CHAIN_NAME,
                Strings.toHexString(CHILD_BRIDGE_ADAPTOR),
                payload,
                address(this)
            )
        );

        vm.expectCall(
            address(mockAxelarGateway),
            abi.encodeWithSelector(
                mockAxelarGateway.callContract.selector,
                CHILD_CHAIN_NAME,
                Strings.toHexString(CHILD_BRIDGE_ADAPTOR),
                payload
            )
        );

        vm.expectEmit(true, true, true, false, address(axelarAdaptor));
        emit MapTokenAxelarMessage(CHILD_CHAIN_NAME, Strings.toHexString(CHILD_BRIDGE_ADAPTOR), payload);

        axelarAdaptor.mapToken{value: callValue}(address(token), token.name(), token.symbol(), token.decimals());
    }

    function test_RevertsIf_mapTokenCalledByNonRootBridge() public {
        address payable prankster = payable(address(0x33));
        uint256 value = 300;

        // Have to call these above so the expectRevert works on the call to mapToken.
        string memory name = token.name();
        string memory symbol = token.symbol();
        uint8 decimals = token.decimals();
        prankster.transfer(value);
        vm.prank(prankster);
        vm.expectRevert(CallerNotBridge.selector);
        axelarAdaptor.mapToken{value: value}(address(token), name, symbol, decimals);
    }

    function test_RevertsIf_mapTokenCalledWithNoValue() public {
        string memory name = token.name();
        string memory symbol = token.symbol();
        uint8 decimals = token.decimals();
        vm.expectRevert(NoGas.selector);
        axelarAdaptor.mapToken{value: 0}(address(token), name, symbol, decimals);
    }
}
