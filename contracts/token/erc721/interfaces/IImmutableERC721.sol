// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


interface IImmutableERC721 is IERC721, IERC721Metadata {
    /// @dev Caller tried to mint an already burned token
    error IImmutableERC721TokenAlreadyBurned(uint256 tokenId);

    /// @dev Caller tried to mint an already burned token
    error IImmutableERC721SendingToZerothAddress();

    /// @dev Caller tried to mint an already burned token
    error IImmutableERC721MismatchedTransferLengths();

    /// @dev Caller tried to mint a tokenid that is above the hybrid threshold
    error IImmutableERC721IDAboveThreshold(uint256 tokenId);

    /// @dev Caller is not approved or owner
    error IImmutableERC721NotOwnerOrOperator(uint256 tokenId);

    /// @dev Current token owner is not what was expected
    error IImmutableERC721MismatchedTokenOwner(uint256 tokenId, address currentOwner);

    /// @dev Signer is zeroth address
    error SignerCannotBeZerothAddress();

    /// @dev Deadline exceeded for permit
    error PermitExpired();

    /// @dev Derived signature is invalid (EIP721 and EIP1271)
    error InvalidSignature();


    /**
     * @notice A singular batch transfer request. The length of the tos and tokenIds must be matching
     *  batch transfers will transfer the specified ids to their matching address via index.
     *
     */
    struct TransferRequest {
        address from;
        address[] tos;
        uint256[] tokenIds;
    }

    /// @notice A singular safe burn request.
    struct IDBurn {
        address owner;
        uint256[] tokenIds;
    }

    /// @notice A singular Mint by id request
    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

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
     * @notice Allows admin grant `user` `MINTER` role
     *  @param user The address to grant the `MINTER` role to
     */
    function grantMinterRole(address user) external;

    /**
     * @notice Allows admin to revoke `MINTER_ROLE` role from `user`
     *  @param user The address to revoke the `MINTER` role from
     */
    function revokeMinterRole(address user) external;

    /**
     * @notice Returns the addresses which have DEFAULT_ADMIN_ROLE
     */
    function getAdmins() external view returns (address[] memory);



    /**
     * The role for default admin.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DEFAULT_ADMIN_ROLE() external view returns(bytes32);

    /**
     * The role for minter.
     */
    // solhint-disable-next-line func-name-mixedcase
    function MINTER_ROLE() external view returns(bytes32);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for permits, as defined by EIP-712
     * @return the bytes32 domain separator
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);


}
