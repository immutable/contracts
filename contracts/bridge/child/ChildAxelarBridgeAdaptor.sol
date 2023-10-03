// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IChildERC20Bridge} from "../interfaces/child/IChildERC20Bridge.sol";
import {IChildAxelarBridgeAdaptorErrors} from "../interfaces/child/IChildAxelarBridgeAdaptor.sol";
import {console2} from "forge-std/Test.sol";

contract ChildAxelarBridgeAdaptor is AxelarExecutable, IChildAxelarBridgeAdaptorErrors {
    /// @notice Address of bridge to relay messages to.
    IChildERC20Bridge public immutable CHILD_BRIDGE;

    constructor(address _gateway, address _childBridge) AxelarExecutable(_gateway) {
        if (_childBridge == address(0)) {
            revert ZeroAddress();
        }

        CHILD_BRIDGE = IChildERC20Bridge(_childBridge);
    }

    /**
     * @dev This function is called by the parent `AxelarExecutable` contract to execute the payload.
     * @custom:assumes `sourceAddress_` is a 20 byte address.
     */
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        // address sourceAddress = address(bytes20(bytes(sourceAddress_)));
        CHILD_BRIDGE.onMessageReceive(sourceChain_, sourceAddress_, payload_);
    }
}