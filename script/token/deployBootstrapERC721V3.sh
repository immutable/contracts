#!/bin/bash

RPC=https://rpc.testnet.immutable.com
# RPC=https://rpc.immutable.com

BLOCKSCOUT=https://explorer.testnet.immutable.com/api?
# BLOCKSCOUT=https://explorer.immutable.com/api?

echo PKEY: $PKEY
echo RPC URL: $RPC
echo Blockscout API Key: $APIKEY
echo Blockscout URI: $BLOCKSCOUT$APIKEY

# To switch from private key environment variable to private key in ledger:
# Remove: 
#    --private-key $PKEY \
# Add:
#    --ledger \
#    --hd-paths "m/44'/60'/0'/0/1" \
# where m/44'/60'/0'/0/1 is the path to the key to use.

# Add resume option if the script fails part way through:
#     --resume \

forge script --rpc-url $RPC \
    --private-key $PKEY \
    --priority-gas-price 10000000000 \
    --with-gas-price     10000000100 \
    -vvv \
    --broadcast \
    --verify \
    --verifier blockscout \
    --verifier-url $BLOCKSCOUT$APIKEY \
    script/token/DeployBootstrapERC721V3.s.sol:DeployBootstrapERC721V3

