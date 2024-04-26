import { defineConfig } from "@wagmi/cli";
import { Abi } from "abitype";

import ImmutableERC721 from "./foundry-out/ImmutableERC721.sol/ImmutableERC721.json";
import ImmutableERC721MintByID from "./foundry-out/ImmutableERC721MintByID.sol/ImmutableERC721MintByID.json";

// https://github.com/wevm/viem/discussions/1009
export default defineConfig({
  out: "abi/generated.ts",
  contracts: [
    {
      name: "ImmutableERC721",
      abi: ImmutableERC721.abi as Abi,
    },
    {
      name: "ImmutableERC721MintByID",
      abi: ImmutableERC721MintByID.abi as Abi,
    },
  ],
});
