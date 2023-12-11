#!/bin/zsh
hardhat test
# Test all contracts in submodules
cd forks
for d in ./*/ ; do (cd "$d" && yarn test); done