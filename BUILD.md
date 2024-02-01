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
yarn test
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
