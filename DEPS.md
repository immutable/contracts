# Dependency Configuration

This repo uses the Foundry tool chain to build and test Solidity code. 

The instructions below were used to install the dependencies.

```
forge install https://github.com/estarriolvetch/solidity-bits --no-commit
forge install https://github.com/GNSPS/solidity-bytes-utils --co-commit
forge install https://github.com/axelarnetwork/axelar-gmp-sdk-solidity --co-commit

forge install openzeppelin-contracts-4.9.3=OpenZeppelin/openzeppelin-contracts@4.9.3 --no-commit
forge install openzeppelin-contracts-upgradeable-4.9.3=OpenZeppelin/openzeppelin-contracts-upgradeable@4.9.3 --no-commit
forge install openzeppelin-contracts-5.0.2=OpenZeppelin/openzeppelin-contracts@5.0.2 --no-commit

forge install immutable-seaport-1.5.0+im1.3=immutable/seaport@1.5.0+im1.3 --no-commit
forge install immutable-seaport-core-1.5.0+im1=immutable/seaport-core@1.5.0+im1 --no-commit

forge install immutable-seaport-1.6.0+im1=immutable/seaport@1.6.0+im1 --no-commit
forge install immutable-seaport-core-1.6.0+im1=immutable/seaport-core@1.6.0+im1 --no-commit
```
