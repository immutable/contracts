# Seaport Deployment Scripts

This directory contains scripts for deploying a set of contracts required to support a Seaport 1.6 trading system. It assumes a ledger wallet is used.

## Environment Variables

The following environment variables must be specified for all scripts. They can be supplied vai the environment or a `.env` file.

* `DRY_RUN`: `true` or `false`.
* `IMMUTABLE_NETWORK`: Must be `mainnet` for Immutable zkEVM Mainnet or `testnet` for Testnet.
* `HD_PATH`: Hierarchical Deterministic path for the ledger wallet. Should of the form `HD_PATH="m/44'/60'/0'/0/0"`.
* `BLOCKSCOUT_APIKEY`: API key for verifying contracts on Blockscout. The key for use with Immutable zkEVM Mainnet will be different to the one used for Testnet. API keys for Immtuable zkEVM Mainnet can be obtained in the [block explorer](https://explorer.immutable.com/account/api-key).

## Deployment

Deploy via the following command:

`./script/trading/seaport16/deploy.sh <CONTRACT_TO_DEPLOY>`

where `CONTRACT_TO_DEPLOY` is one of `ConduitController`, `ImmutableSeaport` or `ImmutableSignedZoneV3`.
