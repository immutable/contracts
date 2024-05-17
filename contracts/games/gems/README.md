# Gem (GM) Game

The GemGame contract emits a single event for the purpose of indexing off-chain.

## Immutable Contract Addresses

| Environment/Network      | Deployment Address | Commit Hash |
|--------------------------|--------------------|-------------|
| imtbl-zkevm-testnet      | 0xe19453c43b35563B8105F8B88DeEDcde999671Cb | [97f00aa69c7cfadddc67ca271593eaa0b1eac940](https://github.com/immutable/contracts/tree/97f00aa69c7cfadddc67ca271593eaa0b1eac940/contracts/games/gems)           |
| imtbl-zkevm-mainnet      | 0x3f04d7a7297d5535595ee0a30071008b54e62a03 | [97f00aa69c7cfadddc67ca271593eaa0b1eac940](https://github.com/immutable/contracts/tree/97f00aa69c7cfadddc67ca271593eaa0b1eac940/contracts/games/gems)           |

# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Internal audit            | April 15, 2024                | [97f00aa69c7cfadddc67ca271593eaa0b1eac940](https://github.com/immutable/contracts/tree/97f00aa69c7cfadddc67ca271593eaa0b1eac940/contracts/games/gems)                | [202404-internal-audit-gm-game](../../../../audits/games/gems/202404-internal-audit-gm-game.pdf) |              |
| Not audited and no threat model              | -                | -               | -              |



# Deployment

**Deploy and verify using CREATE3 factory contract:**

This repo includes a script for deploying via a CREATE3 factory contract. The script is defined as a test contract as per the examples [here](https://book.getfoundry.sh/reference/forge/forge-script#examples) and can be found in `./script/games/gems/DeployGemGame.sol`.

See the `.env.example` for required environment variables.

```sh
forge script script/games/gems/DeployGemGame.sol --tc DeployGemGame --sig "deploy()" -vvv --rpc-url {rpc-url} --broadcast --verifier-url https://explorer.immutable.com/api --verifier blockscout --verify --gas-price 10gwei
```

Optionally, you can also specify `--ledger` or `--trezor` for hardware deployments. See docs [here](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---hardware-wallet).
