# Allowlist contracts

The OperatorAllowlist contracts provide functionality for enabling token contract approvals and transfers to be restricted to allowlisted users. This enables on-chain royalties to be enforced by restricting a contract's transfers to Immutable's version of the Seaport contract that honors royalties.

[Read more](https://docs.immutable.com/docs/zkEVM/products/minting/royalties/allowlist-spec)

## OperatorAllowlist

OperatorAllowlist is a contract implementation of an Allowlist registry, storing addresses and bytecode which are allowed to be approved operators and execute transfers of interfacing token contracts (e.g. ERC721/ERC1155). The registry will be a deployed contract that tokens may interface with and point to.

## IOperatorAllowlist

IOperatorAllowlist is an interface required for interacting with an OperatorAllowlist compliant contract.

## OperatorAllowlistEnforced

OperatorAllowlistEnforced is an abstract contract that token contracts can inherit in order to set the address of the OperatorAllowlist registry that it will interface with, so that the token contract may enable the restriction of approvals and transfers to allowlisted users.
