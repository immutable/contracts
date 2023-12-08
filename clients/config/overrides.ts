import { CallOverrides } from "@ethersproject/contracts";

// https://docs.immutable.com/docs/zkEVM/architecture/gas-config
export const defaultGasOverrides: CallOverrides = {
  maxPriorityFeePerGas: 10e9, // 10 Gwei
  maxFeePerGas: 15e9,
};
