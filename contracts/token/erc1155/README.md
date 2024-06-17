# ERC 1155 Tokens

This directory contains ERC 1155 token contracts that game studios could choose to use
directly or extend.

| Contract                | Description                                                                        |
|-------------------------|------------------------------------------------------------------------------------|
| preset/ImmutableERC1155 | Provides basic ERC1155 contract that support Burnable, Permit and Royalty features | 

[Read more On the EIP](https://eips.ethereum.org/EIPS/eip-1155)

## ImmutableERC1155

The ImmutableERC1155 contract allows clients to mint multiple different tokens with different token ids within the
same collection. The contract features methods to allow for minting multiples of multiple token ids to simplify the
minting flow and reduce gas costs. This contract is built on top of
the [Openzeppelin implementation of EIP-1155](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol).

### Features

- Permits: Includes the permit method for gasless approvals using ECDSAPermit signatures.
- Royalties: Implements royalty tracking and retrieval as per the EIP-2981 standard.
- AccessControl: Provides role-based access control for granting, revoking, and retrieving roles.
- Base URI: Allows for setting a base URI for all token URIs.
- Contract URI: Allows for setting a URI for a contract level metadata.
- Operator Allowlist: Enforces Operator Allowlist to ensure royalties are respected by the operator.

## Status

Contract threat models and audits:

| Description    | Date         | Version Audited                                                                                 | Link to Report                                                                                                    |
|----------------|--------------|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| Internal audit | Feb 21, 2024 | [b3e2858](https://github.com/immutable/contracts/tree/b3e28586f16cc3759b66a3d825af3b9f78a49783) | [audits/token/202312-threat-model-preset-erc1155.md](../../../audits/token/202312-threat-model-preset-erc1155.md) |

## Architecture

![ImmutableERC1155 Architecture](../../../audits/token/202312-threat-model-preset-erc1155/ImmutableERC1155.jpg)

## Contracts

Following contracts are not intended to be upgradable.

### preset/ImmutableERC1155

The ImmutableERC1155 contract is a version of the Immutable's preset 1155 contract. It has been internally audited and
is ready to be used. The contract contains all external facing interfaces that are needed to interact(read and write)
with deployed ERC1155 collections.

### abstract/ERC1155Permit

This is an abstract contract used as an ancestor to the preset 1155. It contains the permit feature for the
preset, allowing token owners to give approval and permission to a secure and trusted actor. This action is gasless for
the token owner but will require gas from the approved operator. Please note that using permits in an ERC1155
collections exposes all the tokens owned by an address to the approved operator. Please double-check to make sure the
operator is secure and trusted.

### abstract/IERC1155Permit

Provides the required interface for ERC1155Permit.

### abstract/ImmutableERC1155Base

This is another abstract contract used as an ancestor to the preset 1155. It implements many of the internal methods for
the preset that are not directly public facing for everyday uses. It contains functionalities to update royalties, set
URIs and manage collection roles.

