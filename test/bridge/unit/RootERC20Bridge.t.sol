// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MockAxelarGateway} from "../../../contracts/bridge/test/MockAxelarGateway.sol";
import {MockAxelarGasService} from "../../../contracts/bridge/test/MockAxelarGasService.sol";
import {RootERC20Bridge, IRootERC20BridgeEvents, IERC20Metadata, IRootERC20BridgeErrors } from "../../../contracts/bridge/RootERC20Bridge.sol";
import {MockRootAxelarBridgeAdaptor} from "../../../contracts/bridge/test/MockRootAxelarBridgeAdaptor.sol";

contract RootERC20BridgeUnitTest is Test, IRootERC20BridgeEvents, IRootERC20BridgeErrors {
    address constant CHILD_BRIDGE = address(3);
    address constant CHILD_BRIDGE_ADAPTOR = address(4);
    string constant CHILD_CHAIN_NAME = "test";

    ERC20PresetMinterPauser public token;
    RootERC20Bridge public rootBridge;
    MockRootAxelarBridgeAdaptor public mockAxelarAdaptor;
    MockAxelarGateway public mockAxelarGateway;
    MockAxelarGasService public axelarGasService;

    function setUp() public {
        token = new ERC20PresetMinterPauser("Test", "TST");

        rootBridge = new RootERC20Bridge();
        mockAxelarGateway = new MockAxelarGateway();
        axelarGasService = new MockAxelarGasService();

        mockAxelarAdaptor = new MockRootAxelarBridgeAdaptor();

        // The specific ERC20 token template does not matter for these unit tests
        rootBridge.initialize(address(mockAxelarAdaptor), CHILD_BRIDGE, address(token));
    }

    function test_InitializeBridge() public {
        assertEq(address(rootBridge.bridgeAdaptor()), address(mockAxelarAdaptor));
        assertEq(rootBridge.childERC20Bridge(), CHILD_BRIDGE);
        assertEq(rootBridge.childTokenTemplate(), address(token));
    }

    function test_RevertIfInitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        rootBridge.initialize(address(mockAxelarAdaptor), CHILD_BRIDGE, address(token));
    }

    function test_RevertIf_InitializeWithAZeroAddress() public {
        RootERC20Bridge bridge = new RootERC20Bridge();
        vm.expectRevert(ZeroAddress.selector);
        bridge.initialize(address(0), address(0), address(0));
    }

    function test_mapToken() public {
        uint256 mapTokenFee = 300;
        address childToken =
            Clones.predictDeterministicAddress(address(token), keccak256(abi.encodePacked(token)), CHILD_BRIDGE);

        vm.expectEmit(true, true, false, false, address(rootBridge));
        emit TokenMapped(address(token), childToken);
        vm.expectCall(
            address(mockAxelarAdaptor),
            mapTokenFee,
            abi.encodeWithSelector(
                mockAxelarAdaptor.mapToken.selector, address(token), token.name(), token.symbol(), token.decimals()
            )
        );

        rootBridge.mapToken{value: mapTokenFee}(token);

        assertEq(rootBridge.rootTokenToChildToken(address(token)), childToken);
    }

    function test_RevertsIf_mapTokenCalledWithZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        rootBridge.mapToken{value: 300}(IERC20Metadata(address(0)));
    }

    function test_RevertsIf_mapTokenCalledTwice() public {
        rootBridge.mapToken{value: 300}(token);
        vm.expectRevert(AlreadyMapped.selector);
        rootBridge.mapToken{value: 300}(token);
    }

    function test_withdrawEth() public {
        uint256 transferAmount = 100;
        address payable withdrawRecipient = payable(address(123));

        // Send `transferAmount` wei to rootBridge
        payable(address(rootBridge)).transfer(transferAmount);

        assertEq(address(rootBridge).balance, transferAmount);
        uint256 preBal = address(withdrawRecipient).balance;

        // withdraw the `transferAmount` wei.
        rootBridge.withdrawEth(withdrawRecipient, transferAmount);

        assertEq(address(rootBridge).balance, 0);
        assertEq(address(withdrawRecipient).balance, preBal + 100);
    }

    function test_RevertsIf_withdrawEthCalledByNonOwner() public {
        vm.prank(address(0xf00f00));
        vm.expectRevert("Ownable: caller is not the owner");
        rootBridge.withdrawEth(payable(address(123)), 100);
    }

    function test_updateBridgeAdaptor() public {
        address newAdaptorAddress = address(0x11111);

        assertEq(address(rootBridge.bridgeAdaptor()), address(mockAxelarAdaptor));
        rootBridge.updateBridgeAdaptor(newAdaptorAddress);
        assertEq(address(rootBridge.bridgeAdaptor()), newAdaptorAddress);
    }

    function test_RevertsIf_updateBridgeAdaptorCalledByNonOwner() public {
        vm.prank(address(0xf00f00));
        vm.expectRevert("Ownable: caller is not the owner");
        rootBridge.updateBridgeAdaptor(address(0x11111));
    }

    function test_RevertsIf_updateBridgeAdaptorCalledWithZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        rootBridge.updateBridgeAdaptor(address(0));
    }
}
