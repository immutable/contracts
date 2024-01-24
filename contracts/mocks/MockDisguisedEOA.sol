// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Used in CREATE2 vector
contract MockDisguisedEOA {
    IERC721 public tokenAddress;

    constructor(IERC721 _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function executeTransfer(address from, address recipient, uint256 _tokenId) external {
        tokenAddress.transferFrom(from, recipient, _tokenId);
    }
}
