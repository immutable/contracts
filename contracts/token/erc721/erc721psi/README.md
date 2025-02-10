# Immutable ERC721 Mint by Quantity Implementation Contracts

The ERC721Psi code in this directory was forked from https://github.com/estarriolvetch/ERC721Psi, with the changes listed in the ERC721Psi Changelog section below.

The ERC721PsiV2 leverages the ERC721Psi code, slightly increasing the minting gas usage but reducing the gas usage for most other functions. The differences between the ERC721Psi and ERC721PsiV2 are listed in the section ERC721PsiV2 and ERC721Psi Differences section.


## ERC721Psi Differences From Upstream

- ERC721Psi: changed `_safeMint(address to, uint256 quantity) internal virtual` to call `ERC721PSI._mint` explicitly to avoid calling ERC721 methods when both are imported in a child contract
- ERC721Psi: changed `_safeMint(address to, uint256 quantity, bytes memory _data` to call `ERC721PSI._mint` explicitly to avoid calling ERC721 methods when both are imported in a child contract


## ERC721PsiV2 and ERC721Psi Differences

- Switched from `solidity-bits'` `BitMaps` implementation to using the `TokenGroup` struct. In `ERC721Psi`, `BitMaps` are used as arrays of bits that have to be traversed. One `TokenGroup` struct holds the token ids for a 256 NFTs. The first NFT in a group is at a multiple of 256. The owner of an NFT for a `TokenGroup` is the `defaultOwner` specified in the `TokenGroup` struct, unless the owner is specified in the `tokenOwners` map. The result of this change is that the owner of a token can be determined using a deterministic amount of gas for `ERC721PsiV2`.
- In `ERC721Psi`, newly minted NFTs are minted to the next available token id. In `ERC721PsiV2`, newly minted NFTs are minted to the next token id that is a multiple of 256. This means that each new mint by quantity is minted to a new token group.
- For `ERC721PsiV2`, when the mint by quantity request is not a multiple of 256 NFTs, there are unused token ids. These token ids are added to a `burned` map in the `TokenGroup`, thus making those token ids unavailable.
- In `ERC721PsiV2`, the balances of account holders and the total supply are maintained as state variables, rather than calculating them when needed, as they are in `ERC721Psi`. The result of this change is that `balanceOf` and `totalSupply` use a deterministic amount of gas.
