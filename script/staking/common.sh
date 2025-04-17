#!/bin/bash
# Load the .env file if it exists
if [ -f .env ]
then
  set -a; source .env; set +a
fi

if [[ $useMainNet -eq 1 ]]
then
    echo Immutable zkEVM Mainnet Configuration
    RPC=https://rpc.immutable.com
    BLOCKSCOUT_URI=https://explorer.immutable.com/api?
    USEMAINNET=true
else
    echo Immutable zkEVM Testnet Configuration
    RPC=https://rpc.testnet.immutable.com
    BLOCKSCOUT_URI=https://explorer.testnet.immutable.com/api?
    USEMAINNET=false
fi
if [ -z "${BLOCKSCOUT_APIKEY}" ]; then
    echo "Error: BLOCKSCOUT_APIKEY environment variable is not set"
    exit 1
fi

if [[ $useLedger -eq 1 ]]
then
    echo " with Ledger Hardware Wallet"
    if [ -z "${LEDGER_HD_PATH}" ]; then
        echo "Error: LEDGER_HD_PATH environment variable is not set"
        exit 1
    fi
else
    echo " with a raw private key"
    if [ -z "${PRIVATE_KEY}" ]; then
        echo "Error: PRIVATE_KEY environment variable is not set"
        exit 1
    fi
fi


echo "Configuration"
echo " RPC: $RPC"
echo " BLOCKSCOUT_APIKEY: $BLOCKSCOUT_APIKEY"
echo " BLOCKSCOUT_URI: $BLOCKSCOUT_URI"
if [[ $useLedger -eq 1 ]]
then
    echo LEDGER_HD_PATH: $LEDGER_HD_PATH
else
    echo " PRIVATE_KEY: <not echoed for your security>" # $PRIVATE_KEY
fi
