#!/bin/bash

# Load the .env file if it exists
if [ -f .env ]
then
  set -a; source .env; set +a
fi

if [ -z "${DRY_RUN}" ]; then
    echo "Error: DRY_RUN variable is not set"
    exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry run mode"
elif [[ "$DRY_RUN" == "false" ]]; then
    echo "Broadcast mode"
else
    echo "Error: DRY_RUN must be either true or false"
    exit 1
fi

if [ -z "${IMMUTABLE_NETWORK}" ]; then
    echo "Error: IMMUTABLE_NETWORK variable is not set"
    exit 1
fi

if [[ "$IMMUTABLE_NETWORK" == "mainnet" ]]; then
    echo Immutable zkEVM Mainnet Configuration
    IMMUTABLE_RPC=https://rpc.immutable.com
    BLOCKSCOUT_URI=https://explorer.immutable.com/api?
elif [[ "$IMMUTABLE_NETWORK" == "testnet" ]]; then
    echo Immutable zkEVM Testnet Configuration
    IMMUTABLE_RPC=https://rpc.testnet.immutable.com
    BLOCKSCOUT_URI=https://explorer.testnet.immutable.com/api?
else
    echo "Error: IMMUTABLE_NETWORK must be either mainnet or testnet"
    exit 1
fi

if [ -z "${HD_PATH}" ]; then
    echo "Error: HD_PATH environment variable is not set"
    exit 1
fi

if [ -z "${BLOCKSCOUT_APIKEY}" ]; then
    echo "Error: BLOCKSCOUT_APIKEY environment variable is not set"
    exit 1
fi

# Check if an argument was provided
if [ -z "$1" ]; then
  echo "Error: No argument provided."
  echo "Usage: $0 <ConduitController|ImmutableSeaport|ImmutableSignedZoneV3>"
  exit 1
fi

contract_to_deploy="$1"
if [[ "$contract_to_deploy" == "ConduitController" ]]; then
    script=script/trading/seaport16/deployConduitController.s.sol
elif [[ "$contract_to_deploy" == "ImmutableSeaport" ]]; then
    script=script/trading/seaport16/deployImmutableSeaport.s.sol
elif [[ "$contract_to_deploy" == "ImmutableSignedZoneV3" ]]; then
    script=script/trading/seaport16/deployImmutableSignedZoneV3.s.sol
else
    echo "Error: contract to deploy must be either ConduitController, ImmutableSeaport or ImmutableSignedZoneV3"
    exit 1
fi

echo "Configuration"
echo " DRY_RUN: $DRY_RUN"
echo " IMMUTABLE_RPC: $IMMUTABLE_RPC"
echo " BLOCKSCOUT_URI: $BLOCKSCOUT_URI"
echo " BLOCKSCOUT_APIKEY: $BLOCKSCOUT_APIKEY"
echo " Script to execute: $script"

# NOTE WELL ---------------------------------------------
# Add resume option if the script fails part way through:
#     --resume \
# To record the transactions but not execute them, remove the --broadcast line.
# NOTE WELL ---------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
    forge script \
        --rpc-url $IMMUTABLE_RPC \
        --priority-gas-price 10000000000 \
        --with-gas-price     10000000100 \
        -vvvv \
        --ledger \
        --hd-paths "$HD_PATH" \
        $script
else
    forge script \
        --rpc-url $IMMUTABLE_RPC \
        --priority-gas-price 10000000000 \
        --with-gas-price     10000000100 \
        -vvvv \
        --broadcast \
        --verify \
        --verifier blockscout \
        --verifier-url $BLOCKSCOUT_URI$BLOCKSCOUT_APIKEY \
        --ledger \
        --hd-paths "$HD_PATH" \
        $script
fi
