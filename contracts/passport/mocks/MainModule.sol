pragma solidity 0.8.17;
// installed under @sequence/wallet-contracts alias instead of @0xsequence/wallet-contracts as the '0x' has problems with typechain
import "../modules/MainModule.sol";

contract MainModuleMock is MainModule {
    constructor(address _factory) MainModule(_factory) {}
}
