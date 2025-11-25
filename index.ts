/**
 * @imtbl/contracts
 *
 * Immutable Smart Contracts - ABIs, addresses, and Solidity source files
 *
 * @example
 * ```ts
 * import {
 *   // ABIs for contracts you deploy
 *   immutableErc721Abi,
 *   // Chain IDs
 *   CHAIN_ID,
 *   // Deployed contract addresses
 *   IMMUTABLE_SEAPORT,
 * } from '@imtbl/contracts';
 *
 * // Get Seaport address for mainnet
 * const seaport = IMMUTABLE_SEAPORT[CHAIN_ID.MAINNET];
 * // '0x6c12aD6F0bD274191075Eb2E78D7dA5ba6453424'
 * ```
 *
 * For Solidity imports:
 * ```solidity
 * import "@imtbl/contracts/contracts/token/erc721/preset/ImmutableERC721.sol";
 * ```
 */

export * from "./src";
