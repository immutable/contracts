//SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

interface IImmutableERC20Errors {
    error RenounceOwnershipNotAllowed();

    error MaxSupplyExceeded(uint256 maxSupply);

    error InvalidMaxSupply();
}
