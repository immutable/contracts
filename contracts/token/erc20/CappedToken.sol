// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CappedToken is ERC20Capped, Ownable {

    constructor(string memory name, string memory symbol, uint256 totalSupply)
        ERC20(name, symbol)
        ERC20Capped(totalSupply)
        Ownable()
    {}

    function mint(address account, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap(), "Mint would exceed max supply");
        _mint(account, amount);
    }
}
