import * as dotenv from "dotenv";
import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-viem";
import "@nomicfoundation/hardhat-verify";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: "cancun",
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.17",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
    overrides: {
      // Seaport 1.5 - requires specific optimizer settings
      "contracts/trading/seaport/ImmutableSeaport.sol": {
        version: "0.8.17",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 10,
          },
        },
      },
      // Seaport 1.6 - uses Cancun EVM
      "contracts/trading/seaport16/ImmutableSeaport.sol": {
        version: "0.8.24",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 10,
          },
          evmVersion: "cancun",
        },
      },
    },
  },
  paths: {
    tests: "./test",
  },
  networks: {
    hardhat: {
      type: "edr-simulated",
      hardfork: "cancun",
    },
    sepolia: {
      type: "http",
      url: process.env.SEPOLIA_URL || "https://sepolia.infura.io/v3/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      type: "http",
      url: process.env.MAINNET_URL || "https://mainnet.infura.io/v3/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY || "",
    },
  },
};

export default config;
