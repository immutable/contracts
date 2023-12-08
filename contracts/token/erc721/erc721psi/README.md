# Immutable Contracts

Forked from https://github.com/estarriolvetch/ERC721Psi. 

## Changelog
- changed `_safeMint(address to, uint256 quantity) internal virtual` to call `ERC721PSI._mint` explicitly to avoid calling ERC721 methods when both are imported in a child contract
- changed `_safeMint(address to, uint256 quantity, bytes memory _data` to call `ERC721PSI._mint` explicitly to avoid calling ERC721 methods when both are imported in a child contract