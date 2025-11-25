/**
 * Deployed contract addresses for Immutable zkEVM
 *
 * @example
 * ```ts
 * import { IMMUTABLE_SEAPORT, CHAIN_ID } from '@imtbl/contracts';
 *
 * // Get address for mainnet
 * const seaportMainnet = IMMUTABLE_SEAPORT[CHAIN_ID.MAINNET];
 *
 * // Use with viem
 * const contract = getContract({
 *   address: IMMUTABLE_SEAPORT[CHAIN_ID.MAINNET],
 *   abi: seaportAbi,
 *   client,
 * });
 * ```
 */



/** Immutable zkEVM Chain IDs */
export const CHAIN_ID = {
  /** Immutable zkEVM Mainnet */
  IMMUTABLE_MAINNET: 13371,
  /** Immutable zkEVM Testnet */
  IMMUTABLE_TESTNET: 13473,
} as const;

export type ChainId = (typeof CHAIN_ID)[keyof typeof CHAIN_ID];

/** Address type for viem compatibility */
type Address = `0x${string}`;

/** Contract address mapping by chain ID */
type ContractAddresses = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: Address;
  [CHAIN_ID.IMMUTABLE_TESTNET]?: Address;
};

// ============================================================================
// Immutable Infrastructure Contracts
// ============================================================================

/** ImmutableSigner - Used for signature verification */
export const IMMUTABLE_SIGNER = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0xcff469E561D9dCe5B1185CD2AC1Fa961F8fbDe61",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0xcff469E561D9dCe5B1185CD2AC1Fa961F8fbDe61",
} as const satisfies ContractAddresses;

/** StartupWalletImpl - Wallet implementation contract */
export const STARTUP_WALLET_IMPL = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x8FD900677aabcbB368e0a27566cCd0C7435F1926",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x8FD900677aabcbB368e0a27566cCd0C7435F1926",
} as const satisfies ContractAddresses;

/** ChildERC20Bridge - Bridge contract for ERC20 tokens */
export const CHILD_ERC20_BRIDGE = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0xb4c3597e6b090A2f6117780cEd103FB16B071A84",
} as const satisfies ContractAddresses;

/** WalletFactory - Factory for creating wallets */
export const WALLET_FACTORY = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x8Fa5088dF65855E0DaF87FA6591659893b24871d",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x8Fa5088dF65855E0DaF87FA6591659893b24871d",
} as const satisfies ContractAddresses;

// ============================================================================
// Trading Contracts (Seaport)
// ============================================================================

/** ImmutableSignedZone - Original signed zone for Seaport */
export const IMMUTABLE_SIGNED_ZONE = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x00338b92Bec262078B3e49BF12bbEA058916BF91",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x8831867E347AB87FA30199C5B695F0A31604Bb52",
} as const satisfies ContractAddresses;

/** ImmutableSignedZoneV2 - V2 signed zone for Seaport */
export const IMMUTABLE_SIGNED_ZONE_V2 = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x1004f9615E79462c711Ff05a386BdbA91a7628C3",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x1004f9615E79462c711Ff05a386BdbA91a7628C3",
} as const satisfies ContractAddresses;

/** SeaportValidator - Validates Seaport orders */
export const SEAPORT_VALIDATOR = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x7dd422357E860bbED7d992C276a54D44cD179818",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x47E927CdcCC7828db2D046d34706660537670F0F",
} as const satisfies ContractAddresses;

/** ImmutableSeaport - Main Seaport exchange contract */
export const IMMUTABLE_SEAPORT = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x6c12aD6F0bD274191075Eb2E78D7dA5ba6453424",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x7d117aA8BD6D31c4fa91722f246388f38ab1942c",
} as const satisfies ContractAddresses;

// ============================================================================
// Asset & Allowlist Contracts
// ============================================================================

/** OperatorAllowlist - Controls approved operators */
export const OPERATOR_ALLOWLIST = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x5F5EBa8133f68ea22D712b0926e2803E78D89221",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x6b969FD89dE634d8DE3271EbE97734FEFfcd58eE",
} as const satisfies ContractAddresses;

/** ContractFactory - Factory for deploying contracts */
export const CONTRACT_FACTORY = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0x612D0C4b92a079D7603C2D898128a72262A141B3",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0x3CC6ee9c987458a0D9f69e49c87816F7DAcA2c19",
} as const satisfies ContractAddresses;

/** ImmutableSwapProxy - Proxy for token swaps */
export const IMMUTABLE_SWAP_PROXY = {
  [CHAIN_ID.IMMUTABLE_MAINNET]: "0xD67cc11151dBccCC424A16F8963ece3D0539BD61",
  [CHAIN_ID.IMMUTABLE_TESTNET]: "0xDdBDa144cEbe1cCd68E746CDff8a6e4Be51A9e98",
} as const satisfies ContractAddresses;
