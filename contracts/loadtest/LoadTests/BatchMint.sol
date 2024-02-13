// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC721Mint} from "./ERC721Mint.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC1155Mint is ERC1155 {
    constructor() ERC1155("https://api.com/v1/") {
    }

    function mint(address to, uint256 amount) public {
        _mint(to, 0, amount, "");
    }
}

contract ERC20Mint is ERC20 {
    constructor() ERC20("ERC20Mint", "20M") {
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}


contract BatchMint {
    ERC20Mint public erc20;
    ERC721Mint public erc721;
    ERC1155Mint public erc1155;

    event ContractsDeployed(address indexed erc20, address indexed erc721, address indexed erc1155);
    constructor() {
        // Deploy ERC20
        erc20 = new ERC20Mint();
        // Deploy ERC721
        erc721 = new ERC721Mint();
        // Deploy ERC1155
        erc1155 = new ERC1155Mint();
        emit ContractsDeployed(address(erc20), address(erc721), address(erc1155));
    }

    function mint(address to, uint256 amount) external {
        erc20.mint(to, amount);
        erc721.mint(to, amount);
        erc1155.mint(to, amount);
    }

    function mintERC721(address to, uint256 amount) external {
        erc721.mint(to, amount);
    }

    function getAddresses() external view returns (address, address, address) {
        return (address(erc20), address(erc721), address(erc1155));
    }

    function approveAll(address spender) external {
        erc20.approve(spender, type(uint256).max);
        erc721.setApprovalForAll(spender, true);
        erc1155.setApprovalForAll(spender, true);
    }

    function tokenId() external view returns (uint256) {
        return erc721.tokenId();
    }
}