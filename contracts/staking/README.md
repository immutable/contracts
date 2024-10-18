# Staking

THIS CODE IS WORK IN PROGRESS

TODO LIST:

* Complete testing
* Add design section to this document
* Write threat model


The Immutable zkEVM staking system consists of the Staking Holder contract. This contract holds staked native IMX. Any account (EOA or contract) can stake any amount at any time. An account can remove all or some of their stake at any time. The contract has the facility to distribute rewards to stakers. 

## Immutable Contract Addresses

| Environment/Network      | Deployment Address | Commit Hash |
|--------------------------|--------------------|-------------|
| Immutable zkEVM Testnet  | Not deployed yet   |   -|
| Immutable zkEVM Mainnet  | Not deployed yet   |   -|

# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Not audited and no threat model              | -                | -               | -              |



# Deployment

**Deploy and verify using CREATE3 factory contract:**

This repo includes a script for deploying via a CREATE3 factory contract. The script is defined as a test contract as per the examples [here](https://book.getfoundry.sh/reference/forge/forge-script#examples) and can be found in `./script/staking/DeployStakeHolder.sol`.

See the `.env.example` for required environment variables.

```sh
forge script script/stake/DeployStakeHolder.sol --tc DeployStakeHolder --sig "deploy()" -vvv --rpc-url {rpc-url} --broadcast --verifier-url https://explorer.immutable.com/api --verifier blockscout --verify --gas-price 10gwei
```

Optionally, you can also specify `--ledger` or `--trezor` for hardware deployments. See docs [here](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---hardware-wallet).
