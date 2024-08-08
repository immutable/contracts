// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721MintableBurnable {
    function safeMint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function safeBurn(address owner, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
