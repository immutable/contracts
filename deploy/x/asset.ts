import { task } from "hardhat/config";
import { getImmutableBridgeAddress, sleep } from "../utils";

// Deploy Immutable X Asset contract
// this is used in the Zero-to-Hero guide
// https://docs.immutable.com/docs/x/zero-to-hero-nft-minting/
const deployAsset = task("deploy:x:asset", "Deploy the Asset contract")
  .addParam("name", "Contract name")
  .addParam("symbol", "Contract symbol")
  .setAction(async (taskArgs, hre) => {
    const [deployer] = await hre.ethers.getSigners();

    const owner = deployer.address;
    const { name, symbol } = taskArgs;
    const allowedNetworks = ["mainnet", "sepolia"];

    if (!allowedNetworks.includes(hre.network.name)) {
      throw new Error(`please pass a valid --network [ ${allowedNetworks.join(" | ")} ]`);
    }

    const Asset = await hre.ethers.getContractFactory("Asset");
    const immutableBridgeAddress = getImmutableBridgeAddress(hre.network.name);
    const asset = await Asset.deploy(owner, name, symbol, immutableBridgeAddress);

    console.log("Deployed Contract Address:", asset.address);
    console.log("Verifying contract in 5 minutes...");
    await sleep(60000 * 5);

    await hre.run("verify:verify", {
      address: asset.address,
      constructorArguments: [owner, name, symbol, immutableBridgeAddress],
    });
  });

export default deployAsset;
