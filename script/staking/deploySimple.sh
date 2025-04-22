#!/bin/bash
# useMainNet: 1 for mainnet, 0 for testnet
useMainNet=0
# useLedger: 1 for ledger, 0 for private key
useLedger=0

FUNCTION_TO_EXECUTE='deploySimple()'

# Set-up variables and execute forge
source $(dirname "$0")/common.sh


