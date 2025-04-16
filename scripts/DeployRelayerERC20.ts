import hre from "hardhat";
import fs from "fs";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  // Deploy the Relayer ERC721
  const erc20Factory = await hre.ethers.getContractFactory("RelayerERC20");
  const relayerERC20 = await erc20Factory.deploy();
  await relayerERC20.deployed();

  console.log(`RelayerERC20 deployed to: ${relayerERC20.address}`);

  fs.writeFileSync("RelayerERC20.json", JSON.stringify({
    address: relayerERC20.address,
  }));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
