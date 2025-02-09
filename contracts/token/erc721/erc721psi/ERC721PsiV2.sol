// SPDX-License-Identifier: MIT
/**
 * Inspired by ERC721Psi: https://github.com/estarriolvetch/ERC721Psi
 */
pragma solidity 0.8.19;

// solhint-disable
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721PsiV2 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private aName;
    string private aSymbol;

    struct TokenGroup {
        // Ownership is a bitmap of 256 NFTs. If a bit is 0, then the default
        // owner owns the NFT.
        uint256 ownership;
        // Burned is a bitmap of 256 NFTs. If a bit is 1, then the NFT is burned.
        uint256 burned;
        // Owner who, but default, owns the NFTs in this group.
        address defaultOwner;
    }

    // Token group bitmap.
    mapping(uint256 => TokenGroup) internal tokenOwners;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    mapping(address => uint256) internal balances;
    uint256 internal supply;

    // The next group to allocated tokens form.
    uint256 private nextGroup;

    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;
    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory _name, string memory _symbol) {
        aName = _name;
        aSymbol = _symbol;
        // Have the first by-quantity NFT to be a multiple of 256 above the base token id.
        uint256 baseId = _startTokenId();
        nextGroup = baseId / 256 + 1;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure virtual returns (uint256) {
        // It will become modifiable in the future versions
        return 0;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        bool exists;
        address owner;
        (, , exists, owner) = _tokenInfo(_tokenId);
        require(exists, "ERC721Psi: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return aName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return aSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    // slither-disable-next-line dead-code
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Psi: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Psi: approve caller is not owner nor approved for all"
        );

        _approve(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721Psi: approved query for nonexistent token");

        return tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721Psi: approve to caller");

        operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Psi: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Psi: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @notice Return the total number of NFTs minted that have not been burned.
     */
    function totalSupply() public view virtual returns (uint256) {
        return supply;
    }

    /**
     * @notice returns the next token id that will be minted for the first
     *  NFT in a call to mintByQuantity or safeMintByQuantity.
     */
    function mintBatchByQuantityNextTokenId() external view returns (uint256) {
        return _groupToTokenId(nextGroup);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, 1, _data),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`).
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        bool exists;
        (, , exists, ) = _tokenInfo(_tokenId);
        return exists;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view virtual returns (bool) {
        bool exists;
        address owner;
        (, , exists, owner) = _tokenInfo(_tokenId);
        require(exists, "ERC721Psi: operator query for nonexistent token");

        return ((_spender == owner) || (_spender == tokenApprovals[_tokenId]) || isApprovedForAll(owner, _spender));
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address _to, uint256 _quantity) internal virtual {
        ERC721PsiV2._safeMint(_to, _quantity, "");
    }

    function _safeMint(address _to, uint256 _quantity, bytes memory _data) internal virtual {
        // need to specify the specific implementation to avoid calling the
        // mint method of erc721 due to matching func signatures
        uint256 firstMintedTokenId = ERC721PsiV2._mintInternal(_to, _quantity);
        require(
            _checkOnERC721Received(address(0), _to, firstMintedTokenId, _quantity, _data),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address _to, uint256 _quantity) internal virtual {
        _mintInternal(_to, _quantity);
    }

    function _mintInternal(address _to, uint256 _quantity) internal virtual returns (uint256) {
        uint256 firstTokenId = _groupToTokenId(nextGroup);

        require(_quantity > 0, "ERC721Psi: quantity must be greater 0");
        require(_to != address(0), "ERC721Psi: mint to the zero address");

        _beforeTokenTransfers(address(0), _to, firstTokenId, _quantity);

        // Mint tokens
        (uint256 numberOfGroupsToMint, uint256 numberWithinGroup) = _groupNumerAndOffset(_quantity);
        uint256 nextGroupOnStack = nextGroup;
        uint256 nextGroupAfterMint = nextGroupOnStack + numberOfGroupsToMint;
        for (uint256 i = nextGroupOnStack; i < nextGroupAfterMint; i++) {
            // Set the default owner for the group.
            TokenGroup storage group = tokenOwners[i];
            group.defaultOwner = _to;
        }
        // If the number of NFTs to mint isn't perfectly a multiple of 256, then there
        // will be one final group that will be partially filled. The group will have
        // the "extra" NFTs burned.
        if (numberWithinGroup == 0) {
            nextGroup = nextGroupAfterMint;
        } else {
            // Set the default owner for the group.
            TokenGroup storage group = tokenOwners[nextGroupAfterMint];
            group.defaultOwner = _to;
            // Burn the rest of the group.
            group.burned = _bitMaskToBurn(numberWithinGroup);
            nextGroup = nextGroupAfterMint + 1;
        }

        // Update balances
        balances[_to] += _quantity;
        supply += _quantity;

        // Emit transfer messages
        uint256 toMasked;
        uint256 end = firstTokenId + _quantity;

        // Use assembly to loop and emit the `Transfer` event for gas savings.
        // The duplicated `log4` removes an extra check and reduces stack juggling.
        // The assembly, together with the surrounding Solidity code, have been
        // delicately arranged to nudge the compiler into producing optimized opcodes.
        assembly {
            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            toMasked := and(_to, _BITMASK_ADDRESS)
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                0, // `address(0)`.
                toMasked, // `to`.
                firstTokenId // `tokenId`.
            )

            // The `iszero(eq(,))` check ensures that large values of `quantity`
            // that overflows uint256 will make the loop run out of gas.
            // The compiler will optimize the `iszero` away for performance.
            for {
                let tokenId := add(firstTokenId, 1)
            } iszero(eq(tokenId, end)) {
                tokenId := add(tokenId, 1)
            } {
                // Emit the `Transfer` event. Similar to above.
                log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
            }
        }

        _afterTokenTransfers(address(0), _to, firstTokenId, _quantity);

        return firstTokenId;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
        (uint256 groupNumber, uint256 groupOffset, bool exists, address owner) = _tokenInfo(_tokenId);
        require(exists, "ERC721Psi: owner query for nonexistent token");
        require(owner == _from, "ERC721Psi: transfer of token that is not own");
        require(_to != address(0), "ERC721Psi: transfer to the zero address");

        _beforeTokenTransfers(_from, _to, _tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        // TODO: This is not done in PSI, but is done in open zeppelin
        //require(ownerOf(_tokenId) == _from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        // Do this in the ERC 721 way, and not the PSI way. That is, don't emit an event.
        delete tokenApprovals[_tokenId];

        // Update balances
        // Copied from Open Zeppelin ERC721 implementation
        unchecked {
            // `_balances[from]` cannot overflow. `from`'s balance is the number of token held,
            // which is at least one before the current transfer.
            // `_balances[to]` could overflow. However, that would require all 2**256 token ids to
            // be minted, which in practice is impossible.
            balances[_from] -= 1;
            balances[_to] += 1;
        }

        TokenGroup storage group = tokenOwners[groupNumber];
        group.ownership = _setBit(group.ownership, groupOffset);
        owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfers(_from, _to, _tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address _to, uint256 _tokenId) internal virtual {
        (, , , address owner) = _tokenInfo(_tokenId);
        // Clear approvals from the previous owner
        _approve(owner, _to, _tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address _owner, address _to, uint256 _tokenId) internal virtual {
        tokenApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _firstTokenId uint256 the first ID of the tokens to be transferred
     * @param _quantity uint256 amount of the tokens to be transfered.
     * @param _data bytes optional data to send along with the call
     * @return r bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _quantity,
        bytes memory _data
    ) private returns (bool r) {
        if (_to.isContract()) {
            r = true;
            for (uint256 tokenId = _firstTokenId; tokenId < _firstTokenId + _quantity; tokenId++) {
                // slither-disable-start calls-loop
                try IERC721Receiver(_to).onERC721Received(_msgSender(), _from, tokenId, _data) returns (bytes4 retval) {
                    r = r && retval == IERC721Receiver.onERC721Received.selector;
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC721Psi: transfer to non ERC721Receiver implementer");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
                // slither-disable-end calls-loop
            }
            return r;
        } else {
            return true;
        }
    }

    /**
     * @notice Fetch token information.
     *
     * @param _tokenId The NFT to determine information about.
     * @return groupNumber The group the NFT is part of.
     * @return offset The bit offset within the group.
     * @return exists True if the NFT has been minted and not burned.
     * @return owner The owner of the NFT.
     */
    function _tokenInfo(uint256 _tokenId) internal view returns (uint256, uint256, bool, address) {
        (uint256 groupNumber, uint256 offset) = _groupNumerAndOffset(_tokenId);
        TokenGroup storage group = tokenOwners[groupNumber];
        address owner = address(0);
        bool exists = false;
        bool changedOwnershipAfterMint = _bitIsSet(group.ownership, offset);
        bool burned = _bitIsSet(group.burned, offset);
        if (!burned) {
            if (changedOwnershipAfterMint) {
                owner = owners[_tokenId];
                exists = true;
            } else {
                owner = group.defaultOwner;
                // Default owner will be zero if the group has never been minted.
                exists = owner != address(0);
            }
        }
        return (groupNumber, offset, exists, owner);
    }

    /**
     * Convert from a token id to a group number and an offset.
     */
    function _groupNumerAndOffset(uint256 _tokenId) private pure returns (uint256, uint256) {
        return (_tokenId / 256, _tokenId % 256);
    }

    function _groupToTokenId(uint256 _nextGroup) private pure returns (uint256) {
        return _nextGroup * 256;
    }

    function _bitIsSet(uint256 _bitMask, uint256 _offset) internal pure returns (bool) {
        uint256 bitSet = 1 << _offset;
        return (bitSet & _bitMask != 0);
    }

    function _setBit(uint256 _bitMask, uint256 _offset) internal pure returns (uint256) {
        uint256 bitSet = 1 << _offset;
        uint256 updatedBitMask = bitSet | _bitMask;
        return updatedBitMask;
    }

    function _bitMaskToBurn(uint256 _offset) internal pure returns (uint256) {
        // Offset will range between 1 and 255. 256 if handled separately.
        // If offset = 1, mask should be 0xffff...ffe
        // If offset = 2, mask should be 0xffff...ffc
        // If offset = 3, mask should be 0xffff...ff8
        uint256 inverseBitMask = (1 << _offset) - 1;
        return ~inverseBitMask;
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    // solhint-disable-next-line no-empty-blocks
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    // solhint-disable-next-line no-empty-blocks
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
}
