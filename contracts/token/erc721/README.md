# ERC 721 Tokens

This directory contains ERC 721 token contracts that game studios could choose to use
directly or extend. The main contracts are shown below. A detailed description of the
all the contracts is contained at the end of this document.

| Contract                               | Description                                   |
|--------------------------------------- |-----------------------------------------------|
| preset/ImmutableERC721                 | ERC721 contract that provides mint by id and mint by quantity. | 
| preset/ImmutableERC721V2               | ImmutableERC721 with improved overall performance. | 
| preset/ImmutableERC721MintByID         | ERC721 that allow mint by id across the entire token range. | 

## Security

These contracts contains Permit methods, allowing the token owner to give a third party operator a Permit which is a signed message that can be used by the third party to give approval to themselves to operate on the tokens owned by the original owner. Users take care when signing messages. If they inadvertantly sign a malicious permit, then the attacker could use use it to gain access to the user's tokens. Read more on the EIP here: [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612).


# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Threat model              | October 2023     |[4ff8003d](https://github.com/immutable/contracts/tree/4ff8003da7f1fd9a6e505646cc519cffe07e4994) | [202309-threat-model-preset-erc721.md](../../../audits/token/202309-threat-model-preset-erc721.md) |
| Internal audit            | November 2023, revised February 2024 | [8ae72094](https://github.com/immutable/contracts/tree/8ae72094ab335c6a88ebabde852040e85cb77880) | [202402-internal-audit-preset-erc721.pdf](../../../audits/token/202402-internal-audit-preset-erc721.pdf)


# Contracts

## Presets

Presets are contracts that game studios could choose to deploy.

### ImmutableERC721 and ImmutableERC721V2

These contracts have the following features:

* Mint by ID for token IDs less than `2^128`.
* Mint by quantity for token IDs greater than `2^128`.
* Permits.

Note: The threshold between mint by ID and mint by quantity can be changed by extending the contracts and 
implementing `mintBatchByQuantityThreshold`.

### ImmutableERC721MintByID

The contract has the following features:

* Mint by ID for any token ID
* Permits.

## Interfaces

The original presets, ImmutableERC721 and ImmutableERC721MintByID did not implement interfaces. To reduce
the number of code differences between ImmutableERC721 and ImmutableERC721V2, ImmutableERC721V2 also does not 
implement interfaces. However, the preset contracts implement the following interfaces:

* ImmutableERC721: IImmutableERC721ByQuantity.sol
* ImmutableERC721V2: IImmutableERC721ByQuantityV2.sol
* ImmutableERC721MintByID: IImmutableERC721.sol

## Abstract and PSI

The contract hierarchy for the preset contracts is shown below. The _Base_ layer combines the ERC 721 capabilities with the operator allow list and access control. The _Permit_ layer adds in the Permit capability. The _Hybrid_ contracts combine mint by ID and mint by quantity capabilities. The _PSI_ contracts provide mint by quantity capability.

```
ImmutableERC721
|- ImmutableERC721HybridBase
   |- OperatorAllowlistEnforced
   |- MintingAccessControl
   |- ERC721HybridPermit
      |- ERC721Hybrid
         |- ERC721PsiBurnable 
         |  |- ERC721Psi
         |- Open Zeppelin's ERC721

ImmutableERC721V2
|- ImmutableERC721HybridBaseV2
   |- OperatorAllowlistEnforced
   |- MintingAccessControl
   |- ERC721HybridPermitV2
      |- ERC721HybridV2
         |- ERC721PsiBurnableV2
         |  |- ERC721PsiV2
         |- Open Zeppelin's ERC721

ImmutableERC721MintByID
|- ImmutableERC721Base
   |- OperatorAllowlistEnforced
   |- MintingAccessControl
   |- ERC721Permit
      |- Open Zeppelin's ERC721Burnable
```



