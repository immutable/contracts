pragma solidity 0.8.19;

interface IRootERC20BridgeAdaptor {
    /**
     * @notice Send a map token message to the child chain via the message passing protocol.
     * @param rootToken The address of the token on the root chain.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The decimals of the token.
     */
    function mapToken(address rootToken, string calldata name, string calldata symbol, uint8 decimals) external payable;
}
