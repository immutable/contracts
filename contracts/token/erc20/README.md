# ERC 20 Tokens

This directory contains ERC 20 token contracts that game studios could choose to use
directly or extend. 

| Contract                               | Description                                   |
|--------------------------------------- |-----------------------------------------------|
| preset/ImmutableERC20MinterBurnerPermit| Provides basic ERC 20 Permit, Capped token supply and burn capability.  | 
| preset/ImmutableERC20FixedSupplyNoBurn | ERC 20 contract with a fixed supply defined at deployment. | 

## ImmutableERC20MinterBurnerPermit

This contract contains Permit methods, allowing the token owner to give a third party operator a Permit which is a signed message that can be used by the third party to give approval to themselves to operate on the tokens owned by the original owner. Users take care when signing messages. If they inadvertantly sign a malicious permit, then the attacker could use use it to gain access to the user's tokens. Read more on the EIP here: [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612).
# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Internal audit            | March 28, 2024   | [b7adf0d7](https://github.com/immutable/contracts/tree/b7adf0d702ea71ae43b65f904c1b18d7cdfbb4a2) | [202403-internal-audit-immutable-erc20.pdf](../../../audits/token/202403-internal-audit-immutable-erc20.pdf) |
| Internal audit            | April 16. 2024   | [aa6c1d4](https://github.com/immutable/contracts/tree/aa6c1d43a4165a6e4d8cde302fe34b424b99bd32) | [202404-internal-audit-immutable-erc20.pdf](../../../audits/token/202404-internal-audit-immutable-erc20.pdf)

