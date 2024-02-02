import { task } from "hardhat/config";
import { sleep } from "../utils";

// Deploy ERC20 token contract with capped supply
// this could be used in a guide for deploying an ERC20 token
const deployERC20Capped = task("deploy:x:erc20capped", "Deploy an ERC20 contract with capped supply")
  .addParam("name", "Token name")
  .addParam("symbol", "Token symbol")
  .addParam("supply", "Total supply of tokens")
  .setAction(async (taskArgs, hre) => {
    // @ts-ignore - ethers
    const [deployer] = await hre.ethers.getSigners();
    console.log(`Deployer Address: ${deployer.address}`);

    const { name, symbol, supply } = taskArgs;
    const allowedNetworks = ["mainnet", "sepolia"];

    if (!allowedNetworks.includes(hre.network.name)) {
      throw new Error(`please pass a valid --network [ ${allowedNetworks.join(" | ")} ]`);
    }

    // @ts-ignore - ethers
    const ERC20 = await hre.ethers.getContractFactory("CappedToken");
    const erc20 = await ERC20.deploy(name, symbol, supply);

    console.log("Deployed Contract Address:", erc20.address);
    console.log("Verifying contract in 2 minutes...");
    await sleep(60000 * 2);

    await hre.run("verify:verify", {
      address: erc20.address,
      constructorArguments: [name, symbol, supply],
      contract: "contracts/token/erc20/CappedToken.sol:CappedToken",
    });
  });

export default deployERC20Capped;
