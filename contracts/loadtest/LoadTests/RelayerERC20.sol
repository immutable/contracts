// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
  *  This is a test token only. You can keep minting tokens ad infinitum.
  */
contract RelayerERC20 is ERC20 {
    constructor() ERC20("RelayerERC20", "R20") {}

    /**
     * mint the requisite amount of tokens to any recipient. This is a test
     * contract as you can keep printing tokens.
     *
     * @param owner Owner of the ERC20 token.
     * @param noOfTokens Numer of tokens to give the recipient. 
     */
    function mint(address owner, uint256 noOfTokens) public {
        require(owner != address(0), "ERC20: address zero is not a valid owner");

        _mint(owner, noOfTokens);
    }

}
