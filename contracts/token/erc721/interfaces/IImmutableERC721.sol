// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {IERC721Metadata} from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {IERC4494} from "../abstract/IERC4494.sol";
import {IMintingAccessControl} from "../../../access/IMintingAccessControl.sol";

import {IImmutableERC721Structs} from "./IImmutableERC721Structs.sol";
import {IImmutableERC721Errors} from "./IImmutableERC721Errors.sol";


interface IImmutableERC721 is IMintingAccessControl, IERC2981, IERC721Metadata, 
           IImmutableERC721Structs, IImmutableERC721Errors, IERC4494, IERC5267 {

    /**
     * @dev Burns `tokenId`.
     *
     * @param tokenId The token id to burn.
     *
     * Note: The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;


    /**
     * @notice Allows minter to mint a token by ID to a specified address
     *  @param to the address to mint the token to
     *  @param tokenId the ID of the token to mint
     */
    function mint(address to, uint256 tokenId) external;
    
    /**
     * @notice Allows minter to mint a token by ID to a specified address with hooks and checks
     *  @param to the address to mint the token to
     *  @param tokenId the ID of the token to mint
     */
    function safeMint(address to, uint256 tokenId) external;

    /**
     * @notice Allows minter to safe mint a number of tokens by ID to a number of specified
     *  addresses with hooks and checks. Check ERC721Hybrid for details on _mintBatchByIDToMultiple
     *  @param mints the list of IDMint struct containing the to, and tokenIds
     */
    function mintBatch(IDMint[] calldata mints) external;

    /**
     * @notice Allows minter to safe mint a number of tokens by ID to a number of specified
     *  addresses with hooks and checks. Check ERC721Hybrid for details on _safeMintBatchByIDToMultiple
     *  @param mints the list of IDMint struct containing the to, and tokenIds
     */
    function safeMintBatch(IDMint[] calldata mints) external;

    /**
     * @notice Allows owner or operator to burn a batch of tokens
     * @param tokenIDs an array of token IDs to burn
     */
    function burnBatch(uint256[] calldata tokenIDs) external;


    /**
     * @notice Allows caller to a burn a number of tokens by ID from a specified address
     *  @param burns the IDBurn struct containing the to, and tokenIds
     */
    function safeBurnBatch(IDBurn[] calldata burns) external;

    /**
     * @notice Allows caller to a transfer a number of tokens by ID from a specified
     *  address to a number of specified addresses
     *  @param tr the TransferRequest struct containing the from, tos, and tokenIds
     */
    function safeTransferFromBatch(TransferRequest calldata tr) external;

    /**
     * @notice returns the number of minted - burned tokens
     */
    function totalSupply() external view returns (uint256);





    /**
     * @notice Returns the domain separator used in the encoding of the signature for permits, as defined by EIP-712
     * @return the bytes32 domain separator
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);


}
