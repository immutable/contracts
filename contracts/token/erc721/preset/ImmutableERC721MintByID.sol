// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../abstract/ImmutableERC721Base.sol";

contract ImmutableERC721MintByID is ImmutableERC721Base {
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
    )
        ImmutableERC721Base(owner, name_, symbol_, baseURI_, contractURI_, _operatorAllowlist, _receiver, _feeNumerator)
    {}

    ///     =====   External functions  =====

    /// @dev Allows minter to mint `tokenID` to `to`
    function safeMint(address to, uint256 tokenID) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenID, "");
        _totalSupply++;
    }

    /// @dev Allows minter to mint `tokenID` to `to`
    function mint(address to, uint256 tokenID) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenID);
        _totalSupply++;
    }

    /// @dev Allows minter to a batch of tokens to a specified list of addresses
    function safeMintBatch(IDMint[] memory mintRequests) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < mintRequests.length; i++) {
            _safeBatchMint(mintRequests[i]);
        }
    }

    /// @dev Allows minter to a batch of tokens to a specified list of addresses
    function mintBatch(IDMint[] memory mintRequests) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < mintRequests.length; i++) {
            _batchMint(mintRequests[i]);
        }
    }

    /// @dev Allows owner or operator to burn a batch of tokens
    function burnBatch(uint256[] calldata tokenIDs) external {
        for (uint i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    /// @dev Burn a batch of tokens, checking the owner of each token first.
    function safeBurnBatch(IDBurn[] memory burns) external {
        _safeBurnBatch(burns);
    }

    /// @dev Allows owner or operator to transfer a batch of tokens
    function safeTransferFromBatch(TransferRequest calldata tr) external {
        if (tr.tokenIds.length != tr.tos.length) {
            revert IImmutableERC721MismatchedTransferLengths();
        }

        for (uint i = 0; i < tr.tokenIds.length; i++) {
            safeTransferFrom(tr.from, tr.tos[i], tr.tokenIds[i]);
        }
    }
}
