# Immutable Contracts

<p align="center"><img src="https://cdn.dribbble.com/users/1299339/screenshots/7133657/media/837237d447d36581ebd59ec36d30daea.gif" width="280"/></p>

Immutable Contracts is a library of smart contracts targeted at developers who wish to quickly build and deploy their smart contracts on Immutable chain, a general-purpose permissionless EVM compatible chain. The library allows developers to build on contracts curated by Immutable, including (but not limited to):

- Token presets:

  - [ERC 721](./contracts/token/erc721/README.md)
  - [ERC 1155](./contracts/token/erc1155/README.md)
  - [ERC 20](./contracts/token/erc20/README.md)

- Utility:

  - [Guarded Multicall](./contracts/multicall/README.md)

These contracts are feature-rich and are the recommended standard on Immutable zkEVM intended for all users and partners within the ecosystem.

## Setup

### Installation

```
$ yarn add @imtbl/contracts
```

### Usage

#### Contracts

Once the `contracts` package is installed, use the contracts from the library by importing them:

```solidity
pragma solidity >=0.8.19 <0.8.29;

import "@imtbl/contracts/contracts/token/erc721/preset/ImmutableERC721.sol";

contract MyERC721 is ImmutableERC721 {
    constructor(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory contractURI,
        address operatorAllowlist,
        address royaltyReceiver,
        uint96 feeNumerator
    ) ImmutableERC721(
        owner,
        name,
        symbol,
        baseURI,
        contractURI,
        operatorAllowlist,
        royaltyReceiver,
        feeNumerator
    )
    {}
}
```

#### Typescript ABIs

`contracts` comes with importable Typescript ABIs that can be used to generate a contract client in conjunction with libraries such as `viem` or `wagmi`, so that you can
interact with deployed preset contracts.

The following Typescript ABIs are available:

- `ImmutableERC721Abi`
- `ImmutableERC721MintByIdAbi`
- `ImmutableERC1155Abi`

An example of how to create and use a contract client in order to interact with a deployed `ImmutableERC721`:

```typescript
import { getContract, http, createWalletClient, defineChain } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { ImmutableERC721MintByIdAbi } from "@imtbl/contracts";

const PRIVATE_KEY = "YOUR_PRIVATE_KEY"; // should be read from environment variable
const CONTRACT_ADDRESS = "YOUR_CONTRACT_ADDRESS"; // should be of type `0x${string}`
const RECIPIENT = "ACCOUNT_ADDRESS"; // should be of type `0x${string}`
const TOKEN_ID = BigInt(1);

const immutableTestnet = defineChain({
  id: 13473,
  name: "imtbl-zkevm-testnet",
  nativeCurrency: { name: "IMX", symbol: "IMX", decimals: 18 },
  rpcUrls: {
    default: {
      http: ["https://rpc.testnet.immutable.com"],
    },
  },
});

const walletClient = createWalletClient({
  chain: immutableTestnet,
  transport: http(),
  account: privateKeyToAccount(`0x${PRIVATE_KEY}`),
});

// Bound contract instance
const contract = getContract({
  address: CONTRACT_ADDRESS,
  abi: ImmutableERC721MintByIdAbi,
  client: walletClient,
});

const txHash = await contract.write.mint([recipient, tokenId]);
console.log(`txHash: ${txHash}`);
```

## Build, Test and Deploy

Information about how to build and test the contracts can be found in our [build information](BUILD.md).

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
