# Immutable ERC721 Mint by Quantity Implementation Contracts

The ERC721Psi code in this directory was forked from https://github.com/estarriolvetch/ERC721Psi, with significant improvements for gas optimization.

## Features

The ERC721Psi implementation provides:

* Gas-efficient batch minting with deterministic gas costs
* Optimized owner lookups using the `TokenGroup` struct
* Deterministic gas usage for `balanceOf` and `totalSupply`

## Implementation Details

### TokenGroup Structure

The implementation uses a `TokenGroup` struct instead of the upstream `BitMaps` approach. One `TokenGroup` struct holds the token ids for 256 NFTs. The first NFT in a group is at a multiple of 256. The owner of an NFT for a `TokenGroup` is the `defaultOwner` specified in the `TokenGroup` struct, unless the owner is specified in the `tokenOwners` map.

This design enables:
- Deterministic gas costs for owner lookups
- Efficient batch minting to token groups
- Consistent gas usage regardless of collection size

### Minting Behavior

Newly minted NFTs are minted to the next token id that is a multiple of 256. This means each new mint by quantity is minted to a new token group.

When the mint by quantity request is not a multiple of 256 NFTs, there are unused token ids. These token ids are added to a `burned` map in the `TokenGroup`, making those token ids unavailable.

### State Variables

Balances of account holders and the total supply are maintained as state variables, rather than calculating them when needed. This ensures `balanceOf` and `totalSupply` use a deterministic amount of gas.

## Differences From Upstream ERC721Psi

- Changed `_safeMint(address to, uint256 quantity) internal virtual` to call `ERC721Psi._mint` explicitly to avoid calling ERC721 methods when both are imported in a child contract
- Changed `_safeMint(address to, uint256 quantity, bytes memory _data)` to call `ERC721Psi._mint` explicitly to avoid calling ERC721 methods when both are imported in a child contract
