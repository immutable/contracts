import hre from "hardhat";
import fs from "fs";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  // Deploy the Relayer ERC721
  const erc721Factory = await hre.ethers.getContractFactory("RelayerERC721");
  const relayerERC721 = await erc721Factory.deploy();
  await relayerERC721.deployed();

  console.log(`RelayerERC721 deployed to: ${relayerERC721.address}`);

  fs.writeFileSync("RelayerERC721.json", JSON.stringify({
    address: relayerERC721.address,
  }));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
