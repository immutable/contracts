pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import { ERC721Royalty } from "../extensions/ERC721Royalty.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721AccessControl } from "../extensions/ERC721AccessControl.sol";

abstract contract ERC721Immutable is ERC721Royalty {

        /// @dev Contract level metadata
    string public contractURI;

    /// @dev Common URIs for individual token URIs
    string public baseURI;

    constructor(
        string memory baseURI_,
        string memory contractURI_
    ) {
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev Allows admin to set the base URI
    function setBaseURI(
        string memory baseURI_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /// @dev Allows admin to set the contract URI
    function setContractURI(
        string memory _contractURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

}