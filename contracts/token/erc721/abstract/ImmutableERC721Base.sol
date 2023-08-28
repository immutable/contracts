//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Token
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// Allowlist
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../../allowlist/AllowlistEnforced.sol";

// Utils
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// Errors
import {IImmutableERC721Errors} from "../../../errors/Errors.sol";

/*
    ImmutableERC721Base is an abstract contract that offers minimum preset functionality without
    an opinionated form of minting. This contract is intended to be inherited and implement it's
    own minting functionality to meet the needs of the inheriting contract.
*/

abstract contract ImmutableERC721Base is
    AllowlistEnforced,
    ERC721Burnable,
    ERC2981,
    IImmutableERC721Errors
{
    using BitMaps for BitMaps.BitMap;
    ///     =====   State Variables  =====

    /// @dev Contract level metadata
    string public contractURI;

    /// @dev Common URIs for individual token URIs
    string public baseURI;

    /// @dev Only MINTER_ROLE can invoke permissioned mint.
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /// @dev Total amount of minted tokens to a non zero address
    uint256 public _totalSupply;

    /// @dev A singular batch mint request
    struct IDMint {
        address to;
        uint256[] tokenIds;
    }

    /// @dev A singular safe burn request.
    struct IDBurn {
        address owner;
        uint256[] tokenIds;
    }

    /// @dev A singular batch transfer request
    struct TransferRequest {
        address from;
        address[] tos;
        uint256[] tokenIds;
    }

    /// @dev A mapping of tokens that have been burned to prevent re-minting
    BitMaps.BitMap _burnedTokens;

    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI` and `tokenURI`
     * Sets the royalty receiver and amount (this can not be changed once set)
     */
    constructor(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address _operatorAllowlist,
        address _receiver,
        uint96 _feeNumerator
    ) ERC721(name_, symbol_) {
        // Initialize state variables
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _setDefaultRoyalty(_receiver, _feeNumerator);
        _setOperatorAllowlistRegistry(_operatorAllowlist);
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    ///     =====   View functions  =====

    /// @dev Returns the baseURI
    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return baseURI;
    }

    /// @dev Returns the supported interfaces
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC2981, AllowlistEnforced)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Returns the addresses which have DEFAULT_ADMIN_ROLE
    function getAdmins() public view returns (address[] memory) {
        uint256 adminCount = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        address[] memory admins = new address[](adminCount);
        for (uint256 i; i < adminCount; i++) {
            admins[i] = getRoleMember(DEFAULT_ADMIN_ROLE, i);
        }

        return admins;
    }

    ///     =====  Public functions  =====

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

    /// @dev Override of setApprovalForAll from {ERC721}, with added Allowlist approval validation
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721) validateApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Override of approve from {ERC721}, with added Allowlist approval validation
    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721) validateApproval(to) {
        super.approve(to, tokenId);
    }

    /// @dev Override of internal transfer from {ERC721} function to include validation
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) validateTransfer(from, to) {
        super._transfer(from, to, tokenId);
    }

    /// @dev Set the default royalty receiver address
    function setDefaultRoyaltyReceiver(
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev Set the royalty receiver address for a specific tokenId
    function setNFTRoyaltyReceiver(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev Set the royalty receiver address for a list of tokenIDs
    function setNFTRoyaltyReceiverBatch(
        uint256[] calldata tokenIds,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenRoyalty(tokenIds[i], receiver, feeNumerator);
        }
    }

    /// @dev Allows admin grant `user` `MINTER` role
    function grantMinterRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, user);
    }

    /// @dev Allows admin to revoke `MINTER_ROLE` role from `user`
    function revokeMinterRole(
        address user
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, user);
    }

    /// @dev returns total number of tokens available(minted - burned)
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    // @dev allows owner or operator to burn a single token
    function burn(uint256 tokenId) public override(ERC721Burnable) {
        super.burn(tokenId);
        _burnedTokens.set(tokenId);
        _totalSupply--;
    }

    /// @dev Burn a token, checking the owner of the token against the parameter first.
    function safeBurn(address owner, uint256 tokenId) public virtual {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != owner) {
            revert IImmutableERC721MismatchedTokenOwner(tokenId, currentOwner);
        }

        burn(tokenId);
    }

    /// @dev Burn a batch of tokens, checking the owner of each token first.
    function _safeBurnBatch(IDBurn[] memory burns) public virtual {
        for (uint i = 0; i < burns.length; i++) {
            IDBurn memory b = burns[i];
            for (uint j = 0; j < b.tokenIds.length; j++) {
                safeBurn(b.owner, b.tokenIds[j]);
            }
        }
    }

    ///     =====  Internal functions  =====

    /// @dev mints specified token ids to specified address
    function _batchMint(IDMint memory mintRequest) internal {
        if (mintRequest.to != address(0)) {
            revert IImmutableERC721SendingToZerothAddress();
        }
        for (uint256 j = 0; j < mintRequest.tokenIds.length; j++) {
            _mint(mintRequest.to, mintRequest.tokenIds[j]);
        }
        _totalSupply = _totalSupply + mintRequest.tokenIds.length;
    }

    /// @dev mints specified token ids to specified address
    function _safeBatchMint(IDMint memory mintRequest) internal {
        if (mintRequest.to == address(0)) {
            revert IImmutableERC721SendingToZerothAddress();
        }
        for (uint256 j; j < mintRequest.tokenIds.length; j++) {
            _safeMint(mintRequest.to, mintRequest.tokenIds[j]);
        }
        _totalSupply = _totalSupply + mintRequest.tokenIds.length;
    }

    /// @dev mints specified token id to specified address
    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        super._mint(to, tokenId);
    }

    /// @dev mints specified token id to specified address
    function _safeMint(address to, uint256 tokenId) internal override(ERC721) {
        if (_burnedTokens.get(tokenId)) {
            revert IImmutableERC721TokenAlreadyBurned(tokenId);
        }
        super._safeMint(to, tokenId);
    }
}
