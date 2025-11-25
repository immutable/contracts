/**
 * @imtbl/contracts
 *
 * Contract ABIs and deployed addresses for Immutable zkEVM
 */

// ABIs - for contracts you deploy
export {
  guardedMulticaller2Abi,
  immutableErc721Abi,
  immutableErc721MintByIdAbi,
  immutableErc1155Abi,
  paymentSplitterAbi,
} from "./generated";

// Chain IDs and deployed addresses
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
