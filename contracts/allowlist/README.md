# Allowlist contracts

The OperatorAllowlist contracts provide functionality for enabling token contract approvals and transfers to be restricted to allowlisted users. This enables on-chain royalties to be enforced by restricting a contract's transfers to Immutable's version of the Seaport contract that honors royalties.

[Read more](https://docs.immutable.com/docs/zkEVM/products/minting/royalties/allowlist-spec)


# Status

Contract audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| -                         | -                | -               | -              |

OperatorAllowlistUpgradeable Deployments: Note: the addresses are for the ERC 1967 Proxy that the implementation contract sits behind.

| Location                  | Version Deployed | Address |
|---------------------------|------------------|---------|
| Immutable zkEVM Testnet   | [929cbb](https://github.com/immutable/contracts/blob/929cbbb9bfabdc854b2c21b1c7a8c7ab396f6676/contracts/allowlist/OperatorAllowlistUpgradeable.sol)     | [0x6b969FD89dE634d8DE3271EbE97734FEFfcd58eE](https://explorer.testnet.immutable.com/address/0x6b969FD89dE634d8DE3271EbE97734FEFfcd58eE)  |
| Immutable zkEVM Mainnet   | [929cbb](https://github.com/immutable/contracts/blob/929cbbb9bfabdc854b2c21b1c7a8c7ab396f6676/contracts/allowlist/OperatorAllowlistUpgradeable.sol)    | [0x5F5EBa8133f68ea22D712b0926e2803E78D89221](https://explorer.immutable.com/address/0x5F5EBa8133f68ea22D712b0926e2803E78D89221?tab=contract)       |


## OperatorAllowlistUpgradeable

OperatorAllowlistUpgradeable is a contract implementation of an Allowlist registry, storing addresses and bytecode which are allowed to be approved operators and execute transfers of interfacing token contracts (e.g. ERC721/ERC1155). The registry will be a deployed contract that tokens may interface with and point to.

## IOperatorAllowlist

IOperatorAllowlist is an interface required for interacting with an OperatorAllowlist compliant contract.

## OperatorAllowlistEnforced

OperatorAllowlistEnforced is an abstract contract that token contracts can inherit in order to set the address of the OperatorAllowlist registry that it will interface with, so that the token contract may enable the restriction of approvals and transfers to allowlisted users.
