import { CallOverrides } from "@ethersproject/contracts";

export const defaultGasOverrides: CallOverrides = {
  maxFeePerGas: 1000000000000,
  maxPriorityFeePerGas: 1000000000000,
};
