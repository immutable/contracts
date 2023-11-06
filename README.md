# Immutable Contracts

<p align="center"><img src="https://cdn.dribbble.com/users/1299339/screenshots/7133657/media/837237d447d36581ebd59ec36d30daea.gif" width="280"/></p>

Immutable Contracts is a library of smart contracts targeted at developers who wish to quickly build and deploy their smart contracts on the Immutable X and Immutable zkEVM, a general-purpose permissionless L2 zero-knowledge rollup. The library allows developers to build on contracts curated by Immutable, including (but not limited to):

- Token presets, e.g. ERC721

- Bridging contracts

- Marketplace and AMM contracts

- Smart Contract Wallets

These contracts are feature-rich and are the recommended standard on Immutable zkEVM intended for all users and partners within the ecosystem.

## Setup

### Installation

```
$ yarn install @imtbl/contracts
```

### Usage

#### Contracts

Once the `contracts` package is installed, use the contracts from the library by importing them:

```solidity
pragma solidity 0.8.19;

import "@imtbl/contracts/contracts/token/erc721/preset/ImmutableERC721.sol";

contract MyERC721 is ImmutableERC721 {
    constructor(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory contractURI,
        address operatorAllowlist,
        address receiver,
        uint96 feeNumerator
    ) ImmutableERC721(
        owner,
        name,
        symbol,
        baseURI,
        contractURI,
        operatorAllowlist,
        receiver,
        feeNumerator
    )
    {}
}
```

#### SDK client

`contracts` comes with a Typescript SDK client that can be used to interface with Immutable preset contracts:

- ImmutableERC721
- ImmutableERC721MintByID

To import and use the ImmutableERC721 contract client:

```typescript
import { ERC721Client } from "@imtbl/contracts";

const contractAddress = YOUR_CONTRACT_ADDRESS;

const client = new ERC721Client(contractAddress);

const mintTransaction = await client.populateMint(receiver, 1);
const tx = await signer.sendTransaction(mintTransaction);
```

## Contribution

We aim to build robust and feature-rich standards to help all developers onboard and build their projects on Immuable zkEVM, and we welcome any and all feedback and contributions to this repository! See our [contribution guideline](CONTRIBUTING.md) for more details on opening Github issues, pull requests requesting features, minor security vulnerabilities and providing general feedback.

## Disclaimers

These contracts are in an experimental stage and are subject to change without notice. The code must still be formally audited or reviewed and may have security vulnerabilities. Do not use it in production. We take no responsibility for your implementation decisions and any security problems you might experience.

We will audit these contracts before our mainnet launch.

## Security

Please responsibly disclose any major security issues you find by reaching out to [security@immutable.com][im-sec].

[im-sec]: mailto:security@immutable.com

## License

Immutable zkEVM Contracts are released under the Apache-2.0 license. See [LICENSE.md](LICENSE.md) for more details.

## Links

### Socials

- [Twitter](https://twitter.com/Immutable)
- [Discord](https://discord.gg/6GjgPkp464)
- [Telegram](https://t.me/immutablex)
- [Reddit](https://www.reddit.com/r/ImmutableX/)
