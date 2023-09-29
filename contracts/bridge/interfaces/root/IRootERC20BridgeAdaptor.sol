// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// TODO: This is likely able to become a generic bridge adaptor, not just for ERC20 tokens.
interface IRootERC20BridgeAdaptor {
    /**
     * @notice Send an arbitrary message to the child chain via the message passing protocol.
     * @param payload The message to send, encoded in a `bytes` array.
     * @param refundRecipient Used if the message passing protocol requires fees & pays back excess to a refund recipient.
     * @dev `payable` because the message passing protocol may require a fee to be paid.
     */
    function sendMessage(bytes calldata payload, address refundRecipient) external payable;
}
