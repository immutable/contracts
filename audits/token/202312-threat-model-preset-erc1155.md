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

ImmutableERC1155 inherits the [ImmutableERC1155Base](../../contracts//token//erc1155//abstract/ImmutableERC1155Base.sol) contract and provides public functions for single and batch minting that are access controlled.

ImmutableERC1155Base inherits contracts:

- `OperatorAllowlistEnforced` - for setting an OperatorAllowlist that enables the restriction of approvals and transfers to allowlisted users
- `ERC1155Permit` - an implementation of the ERC1155 Permit extension from Open Zeppelin allowing approvals to be made via EIP712 signatures, to allow for gasless transactions from the token owners.
- `ERC2981` - an implementation of the NFT Royalty Standard for retrieving royalty payment information
- `MintingAccessControl` - implements access control for the `minter` role

The ERC1155Permit implementation inherits the OpenZeppelin [ERC1155Burnable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/ERC1155Burnable.sol) contract, which provides the public burn methods to be used by the client.

#### Modifications From Base Implementation

- Added total supply tracking for each token id. This will be managed via the pre-transfer hook called by mint, burn and transfer methods
- Added Permits to allow unapproved wallets to become approved without the owner spending gas.
- Override `uri` to return `baseURI` field to keep in standard with ImmutableERC721
- Added `baseURI` to replace `uri` to encourage the usage of `baseURI`

## Attack Surfaces

ERC1155 only has `setApproveForAll` as it's approval method. Meaning any flow that requires a 3rd party to operate on a set of tokens owned by another wallet will grant the third party access to all of that specific wallet's tokens. The third party needs to be entirely trustworthy. The owner needs to be diligent on revoking unrestricted access when not needed.

The contract has no access to any funds. Additional risks can come from compromised keys that are responsible for managing the admin roles that control the collection. As well as permits and approves if an user was tricked into creating a permit that can be validated by a malicious eip1271 wallet giving them permissions to the user's token.

Potential Attacks:

- Compromised Admin Keys:
  - The compromised keys are able to assign the `MINTER_ROLE` to malicious parties and allow them to mint tokens to themselves without restriction
  - The compromised keys are able to update the `OperatorAllowList` to white list malicious contracts to be approved to operate on tokens within the collection
- Compromised Offchain auth:
  - Since EIP4494 combined with EIP1271 relies on off chain signatures that are not standard to the ethereum signature scheme, user auth info can be compromised and be used to create valid EIP1271 signatures.

## Tests

`forge test` will run all the related tests.

## Diagram

![](./202312-threat-model-preset-erc1155/ImmutableERC1155.jpg)
