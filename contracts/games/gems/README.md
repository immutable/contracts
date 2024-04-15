# Gem (GM) Game

The GemGame contract emits a single event for the purpose of indexing off-chain.

## Immutable Contract Addresses

| Environment/Network      | Deployment Address | Commit Hash |
|--------------------------|--------------------|-------------|
| imtbl-zkevm-testnet      | -                  | -           |
| imtbl-zkevm-mainnet      | -                  | -           |

# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Not audited and no threat model              | -                | -               | -              |


**Deploy and verify using CREATE3 factory contract:**

This repo includes a script for deploying via a CREATE3 factory contract. The script is defined as a test contract as per the examples [here](https://book.getfoundry.sh/reference/forge/forge-script#examples) and can be found in `./script/games/gems/DeployGemGame.sol`.

See the `.env.example` for required environment variables.

```sh
forge script script/games/gems/DeployGemGame.sol --tc DeployGemGame --sig "deploy()" -vvv --rpc-url {rpc-url} --broadcast --verifier-url https://explorer.immutable.com/api --verifier blockscout --verify --gas-price 10gwei
```

Optionally, you can also specify `--ledger` or `--trezor` for hardware deployments. See docs [here](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---hardware-wallet).