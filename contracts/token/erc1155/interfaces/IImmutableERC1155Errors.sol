//SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <=0.8.27;

interface IImmutableERC1155Errors {
    /// @dev Deadline exceeded for permit
    error PermitExpired();

    /// @dev Derived signature is invalid (EIP721 and EIP1271)
    error InvalidSignature();
}
