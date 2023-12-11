#!/bin/zsh
hardhat compile
# Compile all contracts in submodules
cd forks
for d in ./*/ ; do (cd "$d" && yarn build); done