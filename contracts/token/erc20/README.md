# ERC 20 Tokens

This directory contains ERC 20 token contracts that game studios could choose to use
directly or extend. 

| Contract                               | Description                                   |
|--------------------------------------- |-----------------------------------------------|
| preset/ImmutableERC20MinterBurnerPermit| Provides basic ERC 20 Permit, Capped token supply and burn capability. Designed to be extended.  | 
| preset/ImmutableERC20FixedSupplyNoBurn | ERC 20 contract with a fixed supply defined at deployment. | 

## ImmutableERC20MinterBurnerPermit

This contract contains Permit methods, allowing the token owner to give a third party operator a `Permit` which is a signed message that can be used by the third party to give approval to themselves to operate on the tokens owned by the original owner. Users of permit should take care of the signed messages, as anyone who has access to this signed message can use it to gain access to the tokens. Read more on the EIP here: [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612).
# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Internal audit            | March 28, 2024   | [b7adf0d7](https://github.com/immutable/contracts/tree/b7adf0d702ea71ae43b65f904c1b18d7cdfbb4a2) | [202403-internal-audit-immutable-erc20.pdf](../../../audits/token/202403-internal-audit-immutable-erc20.pdf) |

