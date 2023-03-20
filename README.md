# Immutable zkEVM Contracts

<p align="center"><img src="https://cdn.dribbble.com/users/1299339/screenshots/7133657/media/837237d447d36581ebd59ec36d30daea.gif" width="280"/></p>

zkEVM Contracts is a library of smart contracts targeted at developers who wish to quickly build and deploy their smart contracts on the Immutable zkEVM, a general-purpose permissionless L2 zero-knowledge rollup. The repository can be found here at [github.com/immutable/zkevm-contracts](https://github.com/immutable/zkevm-contracts). For documentation on these contracts, please refer to [docs.immutable.com/](https://docs.immutable.com/).

The library allows developers to build on contracts curated by Immutable, including (but not limited to):

* Token presets, e.g. ERC721

* Bridging contracts

* Marketplace and AMM contracts 

* Smart Contract Wallets 

These contracts are feature-rich and are the recommended standard on Immutable zkEVM intended for all users and partners within the ecosystem.

## Setup

### Installation

```
$ npm install @imtbl/zkevm-contracts
```

### Usage
Once the `zkevm-contracts` package is installed, use the contracts from the library by importing them:

```solidity
pragma solidity ^0.8.0;

import "@imtbl/zkevm-contracts/contracts/token/erc721/ImmutableERC721PermissionedMintable.sol";

contract MyERC721 is ImmutableERC721PermissionedMintable {
    constructor(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory contractURI
    ) ImmutableERC721PermissionedMintable(
      owner, 
      name, 
      symbol, 
      baseURI, 
      contractURI
    ) 
    {}
}
```

## Contribution

We aim to build robust and feature-rich standards to help all developers onboard and build their projects on Immuable zkEVM, and we welcome any and all feedback and contributions to this repository! See our [contribution guideline](CONTRIBUTING.md) for more details on opening Github issues, pull requests requesting features, minor security vulnerabilities and providing general feedback.


## Disclaimers

These contracts are in an experimental stage and are subject to change without notice. The code must still be formally audited or reviewed and may have security vulnerabilities. Do not use it in production. We take no responsibility for your implementation decisions and any security problems you might experience.

We will audit these contracts before our mainnet launch.

## Security

Please responsibly disclose any major security issues you find by reaching out to [TODO: security email address]

## License

Immutable zkEVM Contracts are released under the Apache-2.0 license. See [LICENSE.md](LICENSE.md) for more details.

## Links

### Socials

- [Twitter](https://twitter.com/Immutable)
- [Discord](https://discord.gg/6GjgPkp464)
- [Telegram](https://t.me/immutablex)
- [Reddit](https://www.reddit.com/r/ImmutableX/)