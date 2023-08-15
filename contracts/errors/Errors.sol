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

        /// @dev Error thrown when calling address is not Allowlisted
    error CallerNotInAllowlist(address caller);

    /// @dev Error thrown when 'from' address is not Allowlisted
    error TransferFromNotInAllowlist(address from);

    /// @dev Error thrown when 'to' address is not Allowlisted
    error TransferToNotInAllowlist(address to);

    /// @dev Error thrown when approve target is not Allowlisted
    error ApproveTargetNotInAllowlist(address target);

    /// @dev Error thrown when approve target is not Allowlisted
    error ApproverNotInAllowlist(address approver);
}

