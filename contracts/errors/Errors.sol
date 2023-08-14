pragma solidity ^0.8.0;

interface IImmutableERC721Errors {
    /// @dev Caller tried to mint an already burned token
    error IImmutableERC721TokenAlreadyBurned(uint256 tokenId);

    /// @dev Caller tried to mint an already burned token
    error IImmutableERC721SendingToZerothAddress();

    /// @dev Caller tried to mint an already burned token
    error IImmutableERC721MismatchedTransferLengths();
}

interface RoyaltyEnforcementErrors {
    /// @dev Caller tried to mint an already burned token
    error RoyaltyEnforcementDoesNotImplementRequiredInterface();
}
