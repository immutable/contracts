#!/bin/bash

echo Blockscout API Key: $APIKEY

forge script --rpc-url https://rpc.immutable.com \
    --priority-gas-price 10000000000 \
    --with-gas-price     10000000100 \
    -vvv \
    --broadcast \
    --ledger \
    --hd-paths "m/44'/60'/0'/0/1" \
    --verify \
    --verifier blockscout \
    --verifier-url https://immutable-mainnet.blockscout.com//api?$APIKEY \
    script/UpgradeToV2.s.sol:UpgradeToV2

