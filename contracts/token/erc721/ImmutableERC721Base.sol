//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Token
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// Royalties
import "@openzeppelin/contracts/token/common/ERC2981.sol";

// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../access/IERC173.sol";

// Whitelist Registry
import "../../royalty-enforcement/IRoyaltyWhitelist.sol";

// Utils
import "@openzeppelin/contracts/utils/Counters.sol";

/*
    ImmutableERC721Base is an abstract contract that offers minimum preset functionality without
    an opinionated form of minting. This contract is intended to be inherited and implement it's
    own minting functionality to meet the needs of the inheriting contract.
*/

abstract contract ImmutableERC721Base is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ERC2981,
    AccessControl,
    IERC173
{
    using Counters for Counters.Counter;

    error CallerNotInWhitelist(address caller);
    error ApproveTargetNotInWhitelist(address target);

    ///     =====   Events           =====

    /// @dev Emitted whenever the contract owner changes the transfer whitelist registry
    event RoyaltytWhitelistRegistryUpdated(address oldRegistry, address newRegistry);

    ///     =====   State Variables  =====

    /// @dev Contract level metadata
    string public contractURI;

    /// @dev Common URIs for individual token URIs
    string public baseURI;

    /// @dev the tokenId of the next NFT to be minted.
    Counters.Counter private nextTokenId;

    /// @dev Owner of the contract (defined for interopability with applications, e.g. storefront marketplace)
    address private _owner;

    /// @dev Interface that implements the `IRoyaltyWhitelist` interface
    IRoyaltyWhitelist public royaltyWhitelist;

    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner_` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI` and `tokenURI`
     */
    constructor (
        address owner_, 
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_ , 
        string memory contractURI_,
        address _receiver, 
        uint96 _feeNumerator
        ) ERC721(name_, symbol_){
        // Initialize state variables
        _setDefaultRoyalty(_receiver, _feeNumerator);
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _owner = owner_;
        baseURI = baseURI_;
        contractURI = contractURI_;

        // Increment nextTokenId to start from 1 (default is 0)
        nextTokenId.increment();

        // Emit events
        emit OwnershipTransferred(address(0), _owner);
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Returns the current owner
    function owner() external view override returns (address) {
        return _owner;
    }

    ///     =====  External functions  =====

    /// @dev Allows admin to set the base URI
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = baseURI_;
    }

    /// @dev Allows admin to set the contract URI
    function setContractURI(string memory _contractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractURI = _contractURI;
    }

    /// @dev Allows admin to update contract owner. Required that new oner has admin role
    function transferOwnership(address newOwner)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, newOwner),
            "New owner does not have default admin role"
        );
        address owner_ = _owner;
        require(owner_ != newOwner, "New owner is currently owner");
        require(msg.sender == owner_, "Caller must be current owner");
        _owner = newOwner;
        emit OwnershipTransferred(owner_, newOwner);
    }

    /// @dev Allows admin to set or update the address of the royalty whitelist registry
    function setRoyaltyWhitelistRegistry(address _royaltyWhitelist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC165(_royaltyWhitelist).supportsInterface(type(IRoyaltyWhitelist).interfaceId), "contract does not implement IRoyaltyWhitelist");

        emit RoyaltytWhitelistRegistryUpdated(address(royaltyWhitelist), _royaltyWhitelist);
        royaltyWhitelist = IRoyaltyWhitelist(_royaltyWhitelist);
    }

    /// @dev Internal hook implemented in {ERC721Enumerable}, required for totalSupply()
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _validateApproval(operator);
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public override {
        _validateApproval(to);
        super.approve(to, tokenId);
    }

    /// @dev Internal function to validate approval targets
    function _validateApproval(address targetApproval) internal view {
        // Check for:
        // 1. approval target is an EOA
        // 2. approval target address is whitelisted or target address bytecode is whitelisted
        if (targetApproval.code.length == 0 || royaltyWhitelist.isAddressWhitelisted(targetApproval)){
            return;
        }
        revert ApproveTargetNotInWhitelist(targetApproval);
    }

    /// @dev Override of internal transfer function to include validation
       function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        _validateTransfer();
        super._transfer(from, to, tokenId);
    }

    /// @dev Internal function to validate whether an address is whitelisted
    function _validateTransfer() internal view {
        // Check for:
        // 1. caller is an EOA
        // 2. caller is an approved address or is the calling address' bytecode approved
        if(msg.sender == tx.origin || royaltyWhitelist.isAddressWhitelisted(msg.sender))
        {
            return;
        }
        revert CallerNotInWhitelist(msg.sender);
    }

    /// @dev Internal function to mint a new token with the next token ID
    function _mintNextToken(address to) internal virtual returns (uint256){
        uint256 newTokenId = nextTokenId.current();
        super._mint(to, newTokenId);
        nextTokenId.increment();
        return newTokenId;
    }
}
