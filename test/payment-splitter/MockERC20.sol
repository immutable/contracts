// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Basic ERC20. It is deployed by the tests in order to help testing the PaymentSplitter ERC20 payment feature

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
