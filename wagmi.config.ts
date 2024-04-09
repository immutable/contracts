import { defineConfig } from "@wagmi/cli";
import { Abi } from "abitype";

import ImmutableERC721 from "./foundry-out/ImmutableERC721.sol/ImmutableERC721.json";
import ImmutableERC721MintByID from "./foundry-out/ImmutableERC721MintByID.sol/ImmutableERC721MintByID.json";
// const sc: typeof ABI.abi = ABI.abi as any as typeof ABI.abi;
// import { foundry } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "src/abi/generated.ts",
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
