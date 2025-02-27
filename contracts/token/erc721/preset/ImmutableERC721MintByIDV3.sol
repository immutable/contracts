// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;


import {ImmutableERC721BaseV3} from "../abstract/ImmutableERC721BaseV3.sol";

contract ImmutableERC721MintByIDV3 is ImmutableERC721BaseV3 {
    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param owner_ The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param name_ The name of the collection
     * @param symbol_ The symbol of the collection
     * @param baseURI_ The base URI for the collection
     * @param contractURI_ The contract URI for the collection
     * @param operatorAllowlist_ The address of the operator allowlist
     * @param royaltyReceiver_ The address of the royalty receiver
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
        address royaltyReceiver_,
        uint96 feeNumerator_
    ) {
        _init(
            owner_,
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            operatorAllowlist_,
            royaltyReceiver_,
            feeNumerator_
        );
    }

    function _init(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address royaltyReceiver_,
        uint96 feeNumerator_
    ) public virtual initializer {
        __ImmutableERC721Base_init(
            owner_,
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            operatorAllowlist_,
            royaltyReceiver_,
            feeNumerator_
        );
    }



    /**
     * @notice Allows minter to mint `tokenID` to `to`
     *  @param to the address to mint the token to
     *  @param tokenID the ID of the token to mint
     */
    function safeMint(address to, uint256 tokenID) external onlyRole(MINTER_ROLE) {
        _totalSupply++;
        _safeMint(to, tokenID, "");
    }

    /**
     * @notice Allows minter to safe mint `tokenID` to `to`
     *  @param to the address to mint the token to
     *  @param tokenID the ID of the token to mint
     */
    function mint(address to, uint256 tokenID) external onlyRole(MINTER_ROLE) {
        _totalSupply++;
        _mint(to, tokenID);
    }

    /**
     * @notice Allows minter to safe mint a batch of tokens to a specified list of addresses
     * @param mintRequests an array of IDmint requests with the token IDs and address to mint to
     */
    function safeMintBatch(IDMint[] calldata mintRequests) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < mintRequests.length; i++) {
            _safeBatchMint(mintRequests[i]);
        }
    }

    /**
     * @notice Allows minter to mint a batch of tokens to a specified list of addresses
     * @param mintRequests an array of IDmint requests with the token IDs and address to mint to
     */
    function mintBatch(IDMint[] calldata mintRequests) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < mintRequests.length; i++) {
            _batchMint(mintRequests[i]);
        }
    }

    /**
     * @notice Allows owner or operator to burn a batch of tokens
     * @param tokenIDs an array of token IDs to burn
     */
    function burnBatch(uint256[] calldata tokenIDs) external virtual {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            burn(tokenIDs[i]);
        }
    }

    /**
     * @notice Burn a batch of tokens, checking the owner of each token first.
     * @param burns an array of IDBurn requests with the token IDs and address to burn from
     */
    function safeBurnBatch(IDBurn[] calldata burns) external virtual {
        _safeBurnBatch(burns);
    }

    /**
     * @notice Allows caller to a transfer a number of tokens by ID from a specified
     *  address to a number of specified addresses
     *  @param tr the TransferRequest struct containing the from, tos, and tokenIds
     */
    function safeTransferFromBatch(TransferRequest calldata tr) external virtual {
        uint256 len = tr.tokenIds.length;
        if (len != tr.tos.length) {
            revert IImmutableERC721MismatchedTransferLengths();
        }

        // An unreachable code compiler warning is mistakenly show for the following line.
        // The issue is that one implementation (ImmutableERC721MintByIDBootstrapV3) would 
        // cause the safeTransferFrom to revert. However, other implementations (this contract
        // and ImmutableERC721MintByIDUpgradeableV3) do not revert.
        // This issue has been previously reported to the Solidity compiler team. 
        //  See: https://github.com/ethereum/solidity/issues/14359
        address from = tr.from;
        for (uint256 i = 0; i < len; i++) {
            safeTransferFrom(from, tr.tos[i], tr.tokenIds[i]);
        }
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __ImmutableERC721MintByIDGap;
    // slither-disable-end unused-state
}
