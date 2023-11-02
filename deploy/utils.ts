export const getImmutableBridgeAddress = (network: string) => {
  switch (network) {
    case "sepolia":
      return "0x2d5C349fD8464DA06a3f90b4B0E9195F3d1b7F98"; // sepolia
    case "mainnet":
      return "0x5FDCCA53617f4d2b9134B29090C87D01058e27e9";
  }
  throw Error("Invalid network selected");
};

export const sleep = (ms: number) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};
