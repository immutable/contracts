import { CallOverrides } from "@ethersproject/contracts";

// https://docs.immutable.com/docs/zkEVM/architecture/gas-config
export const defaultGasOverrides: CallOverrides = {
  maxPriorityFeePerGas: 100e9, // 100 Gwei
  maxFeePerGas: 150e9,
};
