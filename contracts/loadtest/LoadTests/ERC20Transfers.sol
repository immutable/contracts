// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Transfer is ERC20 {
    constructor(address[] memory wallets) ERC20("ERC20Transfer", "20T") {
        for (uint256 i; i < wallets.length; i++) {
            _mint(wallets[i], 1000000000000000000000);
        }
    }

    function transferMany(address to, uint256 amount) external {
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
        _transfer(msg.sender, to, amount);
    }
}