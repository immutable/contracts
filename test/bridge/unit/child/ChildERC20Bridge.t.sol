// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ChildERC20Bridge, IChildERC20BridgeEvents, IERC20Metadata, IChildERC20BridgeErrors } from "../../../../contracts/bridge/child/ChildERC20Bridge.sol";
import {ChildERC20} from "../../../../contracts/bridge/child/ChildERC20.sol";
import {MockAdaptor} from "../../../../contracts/bridge/test/root/MockAdaptor.sol";

contract ChildERC20BridgeUnitTest is Test, IChildERC20BridgeEvents, IChildERC20BridgeErrors {
    address constant ROOT_BRIDGE = address(3);
    string public ROOT_BRIDGE_ADAPTOR = Strings.toHexString(address(4));
    string constant ROOT_CHAIN_NAME = "test";

    ChildERC20 public token;
    ChildERC20 public rootToken;
    ChildERC20Bridge public childBridge;

    function setUp() public {
        rootToken = new ChildERC20();
        rootToken.initialize(address(456), "Test", "TST", 18);

        token = new ChildERC20();
        token.initialize(address(123), "Test", "TST", 18);

        childBridge = new ChildERC20Bridge();

        childBridge.initialize(address(this), ROOT_BRIDGE_ADAPTOR, address(token), ROOT_CHAIN_NAME);
    }

    function test_Initialize() public {
        assertEq(address(childBridge.bridgeAdaptor()), address(address(this)));
        assertEq(childBridge.rootERC20BridgeAdaptor(), ROOT_BRIDGE_ADAPTOR);
        assertEq(childBridge.childTokenTemplate(), address(token));
        assertEq(childBridge.rootChain(), ROOT_CHAIN_NAME);
    }

    function test_RevertIfInitializeTwice() public {
        vm.expectRevert("Initializable: contract is already initialized");
        childBridge.initialize(address(this), ROOT_BRIDGE_ADAPTOR, address(token), ROOT_CHAIN_NAME);
    }

    function test_RevertIf_InitializeWithAZeroAddress() public {
        ChildERC20Bridge bridge = new ChildERC20Bridge();
        vm.expectRevert(ZeroAddress.selector);
        bridge.initialize(address(0), ROOT_BRIDGE_ADAPTOR, address(0), ROOT_CHAIN_NAME);
    }

    function test_RevertIf_InitializeWithAnEmptyBridgeAdaptorString() public {
        ChildERC20Bridge bridge = new ChildERC20Bridge();
        vm.expectRevert(InvalidRootERC20BridgeAdaptor.selector);
        bridge.initialize(address(this), "", address(token), ROOT_CHAIN_NAME);
    }


    function test_RevertIf_InitializeWithAnEmptyChainNameString() public {
        ChildERC20Bridge bridge = new ChildERC20Bridge();
        vm.expectRevert(InvalidRootChain.selector);
        bridge.initialize(address(this), ROOT_BRIDGE_ADAPTOR, address(token), "");
    }

    function test_onMessageReceive_EmitsTokenMappedEvent() public {
        address childToken =
            Clones.predictDeterministicAddress(address(token), keccak256(abi.encodePacked(rootToken)), address(childBridge));

        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());

        vm.expectEmit(true, true, false, false, address(childBridge));
        emit L2TokenMapped(address(rootToken), childToken);

        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);

    }

    function test_onMessageReceive_SetsTokenMapping() public {
        address childToken =
            Clones.predictDeterministicAddress(address(token), keccak256(abi.encodePacked(rootToken)), address(childBridge));

        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());

        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
        assertEq(childBridge.rootTokenToChildToken(address(rootToken)), childToken);
    }

    function test_onMessageReceive_DeploysERC20() public {
        address childToken =
            Clones.predictDeterministicAddress(address(token), keccak256(abi.encodePacked(rootToken)), address(childBridge));

        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());

        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);

        assertEq(ChildERC20(childToken).symbol(), rootToken.symbol());
    }


    function test_RevertsIf_onMessageReceiveCalledWithMsgSenderNotBridgeAdaptor() public {
        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());
        
        vm.expectRevert(NotBridgeAdaptor.selector);
        vm.prank(address(123));
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
    }
    function test_RevertsIf_onMessageReceiveCalledWithSourceChainNotRootChain() public {
        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());
        
        vm.expectRevert(InvalidSourceChain.selector);
        childBridge.onMessageReceive("FAKE_CHAIN", ROOT_BRIDGE_ADAPTOR, data);
    }

    function test_RevertsIf_onMessageReceiveCalledWithSourceAddressNotRootAdaptor() public {
        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());
        
        vm.expectRevert(InvalidSourceAddress.selector);
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, Strings.toHexString(address(456)), data);
    }

    function test_RevertsIf_onMessageReceiveCalledWithDataLengthZero() public {
        bytes memory data = "";
        vm.expectRevert(InvalidData.selector);
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
    }

    function test_RevertsIf_onMessageReceiveCalledWithDataInvalid() public {
        bytes memory data = abi.encode("FAKEDATA", address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());
        
        vm.expectRevert(InvalidData.selector);
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
    }

    function test_RevertsIf_onMessageReceiveCalledWithZeroAddress() public {
        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(0), rootToken.name(), rootToken.symbol(), rootToken.decimals());
        
        vm.expectRevert(ZeroAddress.selector);
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
    }

    function test_RevertsIf_onMessageReceiveCalledTwice() public {
        bytes memory data = abi.encode(childBridge.MAP_TOKEN_SIG(), address(rootToken), rootToken.name(), rootToken.symbol(), rootToken.decimals());
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
        vm.expectRevert(AlreadyMapped.selector);
        childBridge.onMessageReceive(ROOT_CHAIN_NAME, ROOT_BRIDGE_ADAPTOR, data);
    }

    function test_updateBridgeAdaptor() public {
        address newAdaptorAddress = address(0x11111);

        assertEq(address(childBridge.bridgeAdaptor()), address(this));
        childBridge.updateBridgeAdaptor(newAdaptorAddress);
        assertEq(address(childBridge.bridgeAdaptor()), newAdaptorAddress);
    }

    function test_RevertsIf_updateBridgeAdaptorCalledByNonOwner() public {
        vm.prank(address(0xf00f00));
        vm.expectRevert("Ownable: caller is not the owner");
        childBridge.updateBridgeAdaptor(address(0x11111));
    }

    function test_RevertsIf_updateBridgeAdaptorCalledWithZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        childBridge.updateBridgeAdaptor(address(0));
    }
}

