# Build and Test Information

## Install

Install dependencies:

```
yarn install
sudo pip3 install slither-analyzer
```

## Build and Test

To build and test the contracts:

```
forge test -vvv
```

## Solidity Linter

To execute solhint:

```
yarn run solhint contracts/**/*.sol
```

To resolve formatting issues:

```
npx prettier --write --plugin=prettier-plugin-solidity 'contracts/**/*.sol'
```


## Static Code Analysis

To run slither:

```
slither --compile-force-framework forge  --foundry-out-directory foundry-out .
```

## Test Coverage

To check the test coverage based on Foundry tests use:

 ```
 forge coverage
 ```

## Performance Tests

To run tests that check the gas usage:

```
forge test -C perfTest --match-path "./perfTest/**" -vvv --block-gas-limit 1000000000000
```

## Fuzz Tests

For ERC721 tests see: [./test/token/erc721/fuzz/README.md](./test/token/erc721/fuzz/README.md)

## Deploy

To deploy the contract with foundry use the following command:

Additional Links: 

[Operator Allowlist Address](https://docs.immutable.com/docs/zkevm/products/minting/royalties/allowlist-spec/#operator-allowlist-values)
```
forge create --rpc-url <RPC_URL> --constructor-args <CONSTRUCTOR_ARGUMENTS> --private-key <DEPLOYER_PRIVATE_KEY> <PATH_TO_CONTRACT:CONTRACT> --gas-price <GAS_PRICE>  --priority-gas-price <PRIORITY_GAS_PRICE>
```

An example for deploying an Immutable ERC721 preset on testnet:

```
forge create \
--rpc-url "https://rpc.testnet.immutable.com" \
--constructor-args "0xD509..." \
"Imaginary Immutable Iguanas" \
"III" \
"https://example-base-uri.com/" \
"https://example-contract-uri.com/" \
"0x6b969FD89dE634d8DE3271EbE97734FEFfcd58eE" \
"0xD509..." \
"2000" \
--private-key "7e03....." \
contracts/token/erc721/preset/ImmutableERC721.sol:ImmutableERC721 \
--gas-price 20000000000 \
--priority-gas-price 20000000000

```
