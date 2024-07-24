import { defineConfig } from "@wagmi/cli";
import { Abi } from "abitype";

import GuardedMulticaller from "./foundry-out/GuardedMulticaller.sol/GuardedMulticaller.json";
import ImmutableERC721 from "./foundry-out/ImmutableERC721.sol/ImmutableERC721.json";
import ImmutableERC721MintByID from "./foundry-out/ImmutableERC721MintByID.sol/ImmutableERC721MintByID.json";
import ImmutableERC1155 from "./foundry-out/ImmutableERC1155.sol/ImmutableERC1155.json";

// https://github.com/wevm/viem/discussions/1009
export default defineConfig({
  out: "abi/generated.ts",
  contracts: [
    {
      name: "GuardedMulticaller",
      abi: GuardedMulticaller.abi as Abi,
    },
    {
      name: "ImmutableERC721",
      abi: ImmutableERC721.abi as Abi,
    },
    {
      name: "ImmutableERC721MintByID",
      abi: ImmutableERC721MintByID.abi as Abi,
    },
    {
      name: "ImmutableERC1155",
      abi: ImmutableERC1155.abi as Abi,
    },
  ],
});
