// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

// Token
import {ERC721Permit, ERC721, ERC721Burnable} from "./ERC721Permit.sol";

// Allowlist
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorAllowlistEnforced} from "../../../allowlist/OperatorAllowlistEnforced.sol";

// Utils
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {AccessControlEnumerable, MintingAccessControl} from "../../../access/MintingAccessControl.sol";

/*
    ImmutableERC721Base is an abstract contract that offers minimum preset functionality without
    an opinionated form of minting. This contract is intended to be inherited and implement it's
    own minting functionality to meet the needs of the inheriting contract.
*/

abstract contract ImmutableERC721Base is OperatorAllowlistEnforced, MintingAccessControl, ERC721Permit, ERC2981 {
    using BitMaps for BitMaps.BitMap;
    ///     =====   State Variables  =====

    /// @notice Contract level metadata
    string public contractURI;

    /// @notice Common URIs for individual token URIs
    string public baseURI;

    /// @notice Total amount of minted tokens to a non zero address
    uint256 public _totalSupply;

    /// @notice A singular batch mint request
    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

    /// @notice A singular safe burn request.
    struct IDBurn {
        address owner;
        uint256[] tokenIds;
    }

    /// @notice A singular batch transfer request
    struct TransferRequest {
        address from;
        address[] tos;
        uint256[] tokenIds;
    }

    /// @notice A mapping of tokens that have been burned to prevent re-minting
    BitMaps.BitMap private _burnedTokens;

    ///     =====   Constructor  =====

    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param owner_ The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param name_ The name of the collection
     * @param symbol_ The symbol of the collection
     * @param baseURI_ The base URI for the collection
     * @param contractURI_ The contract URI for the collection
     * @param operatorAllowlist_ The address of the operator allowlist
     * @param receiver_ The address of the royalty receiver
     * @param feeNumerator_ The royalty fee numerator
     * @dev the royalty receiver and amount (this can not be changed once set)
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address receiver_,
        uint96 feeNumerator_
    ) ERC721Permit(name_, symbol_) {
        // Initialize state variables
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _setDefaultRoyalty(receiver_, feeNumerator_);
        _setOperatorAllowlistRegistry(operatorAllowlist_);
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    /**
     * @notice Set the default royalty receiver address
     *  @param receiver the address to receive the royalty
     *  @param feeNumerator the royalty fee numerator
     *  @dev This can only be called by the an admin. See ERC2981 for more details on _setDefaultRoyalty
     */
    function setDefaultRoyaltyReceiver(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty receiver address for a specific tokenId
     *  @param tokenId the token to set the royalty for
     *  @param receiver the address to receive the royalty
     *  @param feeNumerator the royalty fee numerator
     *  @dev This can only be called by the a minter. See ERC2981 for more details on _setTokenRoyalty
     */
    function setNFTRoyaltyReceiver(uint256 tokenId, address receiver, uint96 feeNumerator)
        public
        onlyRole(MINTER_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty receiver address for a list of tokenId
     *  @param tokenIds the list of tokens to set the royalty for
     *  @param receiver the address to receive the royalty
     *  @param feeNumerator the royalty fee numerator
     *  @dev This can only be called by the a minter. See ERC2981 for more details on _setTokenRoyalty
     */
    function setNFTRoyaltyReceiverBatch(uint256[] calldata tokenIds, address receiver, uint96 feeNumerator)
        public
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenRoyalty(tokenIds[i], receiver, feeNumerator);
        }
    }

    /**
     * @notice allows owner or operator to burn a single token
     *  @param tokenId the token to burn
     *  @dev see ERC721Burnable for more details
     */
    function burn(uint256 tokenId) public override(ERC721Burnable) {
        super.burn(tokenId);
        _burnedTokens.set(tokenId);
        // slither-disable-next-line costly-loop
        _totalSupply--;
    }

    /**
     * @notice Burn a token, checking the owner of the token against the parameter first.
     *  @param owner the owner of the token
     *  @param tokenId the token to burn
     */
    function safeBurn(address owner, uint256 tokenId) public virtual {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != owner) {
            revert IImmutableERC721MismatchedTokenOwner(tokenId, currentOwner);
        }

        burn(tokenId);
    }

    /**
     * @notice Burn a batch of tokens, checking the owner of the token against the parameter first.
     *  @param burns list of burn requests including token id and owner address
     */
    function _safeBurnBatch(IDBurn[] calldata burns) public virtual {
        for (uint256 i = 0; i < burns.length; i++) {
            IDBurn calldata b = burns[i];
            for (uint256 j = 0; j < b.tokenIds.length; j++) {
                safeBurn(b.owner, b.tokenIds[j]);
            }
        }
    }

    /**
     * @notice sets the base uri for the collection. Permissioned to only the admin role
     * @param baseURI_ the new baseURI to set
     */
    function setBaseURI(string memory baseURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    /**
     * @notice sets the contract uri for the collection. Permissioned to only the admin role
     * @param _contractURI the new baseURI to set
     */
    function setContractURI(string memory _contractURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    /**
     * @inheritdoc ERC721
     * @dev Note it will validate the operator in the allowlist
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721) validateApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Returns the supported interfaces
     *  @param interfaceId the interface to check for support
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Permit, ERC2981, OperatorAllowlistEnforced, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice returns the number of minted - burned tokens
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @inheritdoc ERC721
     * @dev Note it will validate the to address in the allowlist
     */
    function _approve(address to, uint256 tokenId) internal override(ERC721) validateApproval(to) {
        super._approve(to, tokenId);
    }

    /**
     * @inheritdoc ERC721Permit
     * @dev Note it will validate the to and from address in the allowlist
     */
    function _transfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Permit)
        validateTransfer(from, to)
    {
        super._transfer(from, to, tokenId);
    }

    ///     =====  Internal functions  =====

    /**
     * @notice mints a batch of tokens with specified ids to a specified address
     *  @param mintRequest list of mint requests including token id and owner address
     *  @dev see ERC721 for more details on _mint
     */
    function _batchMint(IDMint calldata mintRequest) internal {
        if (mintRequest.to == address(0)) {
            revert IImmutableERC721SendingToZerothAddress();
        }

        // slither-disable-next-line costly-loop
        _totalSupply = _totalSupply + mintRequest.tokenIds.length;
        for (uint256 j = 0; j < mintRequest.tokenIds.length; j++) {
            _mint(mintRequest.to, mintRequest.tokenIds[j]);
        }
    }

    /**
     * @notice safe mints a batch of tokens with specified ids to a specified address
     *  @param mintRequest list of burn requests including token id and owner address
     *  @dev see ERC721 for more details on _safeMint
     */
    function _safeBatchMint(IDMint calldata mintRequest) internal {
        if (mintRequest.to == address(0)) {
            revert IImmutableERC721SendingToZerothAddress();
        }
        for (uint256 j; j < mintRequest.tokenIds.length; j++) {
            _safeMint(mintRequest.to, mintRequest.tokenIds[j]);
        }
        // slither-disable-next-line costly-loop
        _totalSupply = _totalSupply + mintRequest.tokenIds.length;
    }

    /**
     * @notice mints specified token id to specified address
     *  @param to the address to mint to
     *  @param tokenId the token to mint
     *  @dev see ERC721 for more details on _mint
     */
    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        super._mint(to, tokenId);
    }

    /**
     * @notice safe mints specified token id to specified address
     *  @param to the address to mint to
     *  @param tokenId the token to mint
     *  @dev see ERC721 for more details on _safeMint
     */
    function _safeMint(address to, uint256 tokenId) internal override(ERC721) {
        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        super._safeMint(to, tokenId);
    }

    /// @notice Returns the baseURI
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }
}
