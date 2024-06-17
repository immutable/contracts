# ERC1155 contracts

The ImmutableERC1155 contracts allows clients to mint multiple different tokens with different token ids within the same collection. The contract features methods to allow for minting multiples of multiple token ids to simplify the minting flow and reduce gas costs. This contract is built on top of the [Openzeppelin implemention of EIP-1155](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol).

[Read more On the Threat Model](../../../../audits/token/202312-threat-model-preset-erc1155.md)

[Read more On the EIP](https://eips.ethereum.org/EIPS/eip-1155)

## preset/ImmutableERC1155

The ImmutableERC1155 contract is a version of the Immutable's preset 1155 contract. It has been internally audited and is ready to be used. The contract contains all external facing interfaces that are needed to interact(read and write) with deployed ERC1155 collections.

## abstract/ERC1155Permit

This is an abstract contract that is used as an ancestor to the preset 1155. It contains the permit feature for the preset, allowing token owners to give approval and permission to a secure and trusted actor. This action is gasless for the token owner but will require gas from the approved operator. Please note that using permits in an ERC1155 collections exposes all the tokens owned by an address to the approved operator. Please double check to make sure the operator is secure and trusted.

## abstract/IERC1155Permit

Provides the required interface for ERC1155Permit.

## abstract/ImmutableERC1155Base

This is another abstract contract used as an ancestor to the preset 1155. It implements many of the internal methods for the preset that are not directly public facing for everyday uses. It contains functionalities to update royalties, set URIs and manage collection roles.
