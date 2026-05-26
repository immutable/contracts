# Immutable Contracts

<p align="center"><img src="https://cdn.dribbble.com/users/1299339/screenshots/7133657/media/837237d447d36581ebd59ec36d30daea.gif" width="280"/></p>

Immutable Contracts is a library of smart contracts targeted at developers who wish to quickly build and deploy their smart contracts on the Immutable X and Immutable zkEVM, a general-purpose permissionless L2 zero-knowledge rollup. The library allows developers to build on contracts curated by Immutable, including (but not limited to):

- Token presets, e.g. ERC721

  - [ImmutableERC721](./contracts/token/erc721/preset/ImmutableERC721.sol)
  - [ImmutableERC721MintByID](./contracts/token/erc721/preset/ImmutableERC721MintByID.sol)
  - [ImmutableERC1155](./contracts/token/erc1155/preset/ImmutableERC1155.sol)
  - [ImmutableERC20MinterBurnerPermit](./contracts/token/erc20/preset/ImmutableERC20MinterBurnerPermit.sol)
  - [ImmutableERC20FixedSupplyNoBurn](./contracts/token/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol)

- Bridging contracts

- Marketplace and AMM contracts

- Smart Contract Wallets

These contracts are feature-rich and are the recommended standard on Immutable zkEVM intended for all users and partners within the ecosystem.

## Setup

### Installation

```
$ yarn add @imtbl/contracts
```

Installing this package pulls **runtime dependencies from npm** — the published tarball intentionally does **not** bundle Seaport, OpenZeppelin, Axelar, or other Solidity libraries as production `dependencies`. TypeScript ABI consumers need only this package plus their own tooling (e.g. `viem`).

### Consuming Solidity sources

Solidity imports use paths such as `@imtbl/contracts/contracts/...` (see [package.json](./package.json) `exports`). Sources under `contracts/` depend on libraries that **you must supply** via your toolchain — for example:

- **`@openzeppelin/contracts`** — listed as a **peer dependency** (`^4.9.6 || ^5.6.1`); align with presets that mix v4 and v5 remappings used in this repo.
- **`@openzeppelin/contracts-upgradeable`** — for upgradeable presets (typically v4.9.x path `openzeppelin-contracts-upgradeable-4.9.6`).
- **`@axelar-network/axelar-gmp-sdk-solidity`** — for deploy / GMP-related contracts (e.g. `OwnableCreate3Deployer`).
- **Immutable Seaport forks** — Seaport-related files expect remappings compatible with Immutable’s Seaport branches (see [remappings.txt](./remappings.txt) and [`.gitmodules`](./.gitmodules) for the git URLs and aliases used in this repo: `seaport`, `seaport-core`, `seaport-types`, `seaport-16`, `seaport-core-16`, `seaport-types-16`).

**Forge:** run `forge install` after clone (see [`.gitmodules`](./.gitmodules)) and use the remappings in [remappings.txt](./remappings.txt). This package does **not** install Seaport or full OpenZeppelin transitively.

### Usage

#### Contracts

Once `@imtbl/contracts` is installed, use the Solidity files from the package by importing them:

```solidity
pragma solidity >=0.8.19 <=0.8.27;

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

The following are exported from the package root:

- `ImmutableERC721Abi`, `ImmutableERC721MintByIdAbi`, `ImmutableERC1155Abi`
- `GuardedMulticaller2Abi`, `PaymentSplitterAbi`
- Deployed address constants (e.g. `IMMUTABLE_SEAPORT`, `CHAIN_ID`)

An example of how to create and use a contract client in order to interact with a deployed `ImmutableERC721` preset:

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

const recipient = RECIPIENT as `0x${string}`;
const tokenId = TOKEN_ID;

const txHash = await contract.write.mint([recipient, tokenId]);
console.log(`txHash: ${txHash}`);
```

## Upgrading from npm `2.x`

**3.0.0** is a breaking release: new ABI names, a smaller package layout, no bundled ethers clients or typechain, and no runtime npm dependencies. See **[MIGRATION.md](./MIGRATION.md)**. To keep the old surface, stay on **`@imtbl/contracts@2.2.18`**.

## Development

```bash
yarn install
forge install
forge build
forge test
yarn build   # TypeScript dist
```

See [BUILD.md](./BUILD.md) for coverage, linting, Slither, and deployment notes.

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
- [Discord](https://discord.gg/immutable-play)
- [Telegram](https://t.me/immutablex)
- [Reddit](https://www.reddit.com/r/ImmutableX/)
