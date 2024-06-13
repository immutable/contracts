## Introduction

This document is a thread model for the preset ERC1155 token contracts built by Immutable.

Contracts covered under this model include:

- [ImmutableERC1155](../../contracts/token/erc1155/preset/ImmutableERC1155.sol)

## Context

The ERC1155 presets built by Immutable were done with the requirements of supply tracking and permits.

- Clients should be able to track how many tokens of a specific token id in a collection is in circulation

- Clients should be able to create permits for unapproved wallets to operate on their behalf

- Minting should be restricted to addresses that were granted the `minter` role

- Only allow operators should be able to modify and assign roles to addresses for administering the collection on chain

- Contracts should not be upgradeable to prevent external developers from getting around royalty requirements

## Design and Implementation

### ImmutableERC1155

The ImmutableERC1155 extends the OpenZeppelin `ERC1155Burnable` contract inheriting the public burn methods to be used by the client.
Permit is added to allow for Gasless transactions from the token owners.

#### Modifications From Base Implementation

- Added total supply tracking for each token id. This will be managed via the pre-transfer hook called by mint, burn and transfer methods
- Added Permits to allow unapproved wallets to become approved without the owner spending gas.
- Override `uri` to return `baseURI` field to keep in standard with ImmutableERC721
- Added `baseURI` to replace `uri` to encourage the usage of `baseURI`

## Attack Surfaces

ERC1155 only has `setApproveForAll` as it's approval method. Meaning any flow that requires a 3rd party to operator on a set of tokens owned by another wallet will grant the third party access to all of that specific wallet's tokens. The third party needs to be entirely trustworthy. The owner needs to be diligent on revoking unrestricted access when not needed.

We can consider implementing a more complicated approval schema if needed. i.e by token id or by token id and amount.

## Tests

`forge test` will run all the related tests.

## Diagram

![](./202312-threat-model-preset-erc1155/ImmutableERC1155.jpg)
