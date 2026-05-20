/**
 * @imtbl/contracts
 *
 * Contract ABIs and deployed addresses for Immutable zkEVM.
 * Use with viem, wagmi, or ethers v6 — no runtime npm dependencies.
 */

export {
  GuardedMulticaller2Abi,
  ImmutableERC721Abi,
  ImmutableERC721MintByIdAbi,
  ImmutableERC1155Abi,
  PaymentSplitterAbi,
} from "./abis";

export {
  CHAIN_ID,
  IMMUTABLE_SIGNER,
  STARTUP_WALLET_IMPL,
  CHILD_ERC20_BRIDGE,
  WALLET_FACTORY,
  IMMUTABLE_SIGNED_ZONE,
  IMMUTABLE_SIGNED_ZONE_V2,
  SEAPORT_VALIDATOR,
  IMMUTABLE_SEAPORT,
  OPERATOR_ALLOWLIST,
  CONTRACT_FACTORY,
  IMMUTABLE_SWAP_PROXY,
} from "./addresses";

export type { ChainId } from "./addresses";
