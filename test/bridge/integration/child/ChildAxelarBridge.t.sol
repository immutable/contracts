// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ChildAxelarBridgeAdaptor} from "../../../../contracts/bridge/child/ChildAxelarBridgeAdaptor.sol";
import {ChildERC20Bridge, IChildERC20BridgeEvents, IERC20Metadata, IChildERC20BridgeErrors } from "../../../../contracts/bridge/child/ChildERC20Bridge.sol";
import {IChildERC20, ChildERC20} from "../../../../contracts/bridge/child/ChildERC20.sol";
import {MockChildAxelarGateway} from "../../../../contracts/bridge/test/child/MockChildAxelarGateway.sol";

contract ChildERC20BridgeIntegrationTest is Test, IChildERC20BridgeEvents, IChildERC20BridgeErrors {
    string public ROOT_ADAPTOR_ADDRESS = Strings.toHexString(address(1));
    string public ROOT_CHAIN_NAME = "ROOT_CHAIN";

    ChildERC20Bridge public childERC20Bridge;
    ChildERC20 public childERC20;
    ChildAxelarBridgeAdaptor public childAxelarBridgeAdaptor;
    MockChildAxelarGateway public mockChildAxelarGateway;

    function setUp() public {
        childERC20 = new ChildERC20();
        childERC20.initialize(address(123), "Test", "TST", 18);

        childERC20Bridge = new ChildERC20Bridge();
        mockChildAxelarGateway = new MockChildAxelarGateway();
        childAxelarBridgeAdaptor = new ChildAxelarBridgeAdaptor(address(mockChildAxelarGateway), address(childERC20Bridge));

        childERC20Bridge.initialize(address(childAxelarBridgeAdaptor), ROOT_ADAPTOR_ADDRESS, address(childERC20), ROOT_CHAIN_NAME);
    }

    function test_ChildTokenMap() public {
        address rootTokenAddress = address(456);
        string memory name = "test name";
        string memory symbol = "TSTNME";
        uint8 decimals = 17;

        bytes32 commandId = bytes32("testCommandId");
        bytes memory payload = abi.encode(childERC20Bridge.MAP_TOKEN_SIG(), rootTokenAddress, name, symbol, decimals);

        address predictedAddress = Clones.predictDeterministicAddress(address(childERC20), keccak256(abi.encodePacked(rootTokenAddress)), address(childERC20Bridge));
        vm.expectEmit(true, true, false, false, address(childERC20Bridge));
        emit L2TokenMapped(rootTokenAddress, predictedAddress);

        // vm.prank(ROOT_ADAPTOR_ADDRESS);
        childAxelarBridgeAdaptor.execute(commandId, ROOT_CHAIN_NAME, ROOT_ADAPTOR_ADDRESS, payload);

        assertEq(childERC20Bridge.rootTokenToChildToken(rootTokenAddress), predictedAddress);

        IChildERC20 childToken = IChildERC20(predictedAddress);
        assertEq(childToken.name(), name);
        assertEq(childToken.symbol(), symbol);
        assertEq(childToken.decimals(), decimals);
    }

    function test_RevertsIf_payloadDataNotValid() public {
        bytes32 commandId = bytes32("testCommandId");
        bytes memory payload = abi.encode("invalid payload");

        vm.expectRevert(InvalidData.selector);
        childAxelarBridgeAdaptor.execute(commandId, ROOT_CHAIN_NAME, ROOT_ADAPTOR_ADDRESS, payload);
    }

    function test_RevertsIf_rootTokenAddressIsZero() public {
        bytes32 commandId = bytes32("testCommandId");
        bytes memory payload = abi.encode(childERC20Bridge.MAP_TOKEN_SIG(), address(0), "test name", "TSTNME", 17);

        vm.expectRevert(ZeroAddress.selector);
        childAxelarBridgeAdaptor.execute(commandId, ROOT_CHAIN_NAME, ROOT_ADAPTOR_ADDRESS, payload);
    }

    function test_RevertsIf_MapTwice() public {
        bytes32 commandId = bytes32("testCommandId");
        bytes memory payload = abi.encode(childERC20Bridge.MAP_TOKEN_SIG(), address(456), "test name", "TSTNME", 17);

        childAxelarBridgeAdaptor.execute(commandId, ROOT_CHAIN_NAME, ROOT_ADAPTOR_ADDRESS, payload);

        vm.expectRevert(AlreadyMapped.selector);
        childAxelarBridgeAdaptor.execute(commandId, ROOT_CHAIN_NAME, ROOT_ADAPTOR_ADDRESS, payload);
    }

    function test_RevertsIf_EmptyData() public {
        bytes32 commandId = bytes32("testCommandId");
        bytes memory payload = "";

        vm.expectRevert(InvalidData.selector);
        childAxelarBridgeAdaptor.execute(commandId, ROOT_CHAIN_NAME, ROOT_ADAPTOR_ADDRESS, payload);
    }

    function test_RevertsIf_InvalidSourceChain() public {
        bytes32 commandId = bytes32("testCommandId");
        bytes memory payload = abi.encode(childERC20Bridge.MAP_TOKEN_SIG(), address(456), "test name", "TSTNME", 17);

        vm.expectRevert(InvalidSourceChain.selector);
        childAxelarBridgeAdaptor.execute(commandId, "FAKE_CHAIN", ROOT_ADAPTOR_ADDRESS, payload);
    }
}
