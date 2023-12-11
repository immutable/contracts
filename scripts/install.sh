#!/bin/zsh
yarn install
# Test all contracts in submodules
cd forks
for d in ./*/ ; do (cd "$d" && yarn install -al); done