// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ChildAxelarBridgeAdaptor} from "../../../../contracts/bridge/child/ChildAxelarBridgeAdaptor.sol";
import {MockChildERC20Bridge} from "../../../../contracts/bridge/test/child/MockChildERC20Bridge.sol";
import {MockChildAxelarGateway} from "../../../../contracts/bridge/test/child/MockChildAxelarGateway.sol";
import {IChildAxelarBridgeAdaptorErrors} from "../../../../contracts/bridge/interfaces/child/IChildAxelarBridgeAdaptor.sol";

contract ChildAxelarBridgeAdaptorUnitTest is Test, IChildAxelarBridgeAdaptorErrors {
    address public GATEWAY_ADDRESS = address(1);

    ChildAxelarBridgeAdaptor public childAxelarBridgeAdaptor;
    MockChildERC20Bridge public mockChildERC20Bridge;
    MockChildAxelarGateway public mockChildAxelarGateway;

    function setUp() public {
        mockChildERC20Bridge = new MockChildERC20Bridge();
        mockChildAxelarGateway = new MockChildAxelarGateway();
        childAxelarBridgeAdaptor = new ChildAxelarBridgeAdaptor(address(mockChildAxelarGateway), address(mockChildERC20Bridge));
    }

    function test_Constructor_SetsValues() public {
        assertEq(address(childAxelarBridgeAdaptor.CHILD_BRIDGE()), address(mockChildERC20Bridge));
        assertEq(address(childAxelarBridgeAdaptor.gateway()), address(mockChildAxelarGateway));
    }

    function test_RevertIf_ConstructorGivenZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        // Gateway address being zero is checked in Axelar's AxelarExecutable smart contract.
        new ChildAxelarBridgeAdaptor(GATEWAY_ADDRESS, address(0));
    }

    function test_Execute() public {
        bytes32 commandId = bytes32("testCommandId");
        string memory sourceChain = "test";
        string memory sourceAddress = Strings.toHexString(address(123));
        bytes memory payload = abi.encodePacked("payload");

        // We expect to call the bridge's onMessageReceive function.
        vm.expectCall(
            address(mockChildERC20Bridge),
            abi.encodeWithSelector(
                mockChildERC20Bridge.onMessageReceive.selector,
                sourceChain,
                sourceAddress,
                payload
            )
        );
        childAxelarBridgeAdaptor.execute(commandId, sourceChain, sourceAddress, payload);
    }
}
