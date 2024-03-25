import hre from "hardhat";
import { readL1KeysFromFile } from "./DeploySeaport";
import fs from "fs";

async function main() {
    // Get private keys
  const l1Keys = await readL1KeysFromFile("l1_keys_transfer.json");
  const wallets = l1Keys.map((key) => new hre.ethers.Wallet(key, hre.ethers.provider));
  const publicKeys = wallets.map((wallet) => wallet.address);

  const [acc1, acc2] = await hre.ethers.getSigners();
  const ERC20Transfer = await hre.ethers.getContractFactory("ERC20Transfer");
  const erc20Transfer = await ERC20Transfer.deploy(publicKeys);
  await erc20Transfer.deployed();

  console.log("ERC20Transfer deployed to:", erc20Transfer.address);

  const txPop = await erc20Transfer.populateTransaction.transferMany("0x1FC1411A3Bd09E63d4A306FD1EB838bA457ddA13", hre.ethers.utils.parseEther("0.000001"));
  const transferData = {
    contractAddress: erc20Transfer.address,
    publicKeys: txPop.data,
  }

  // Write transfer data
  fs.writeFileSync("transfer_data.json", JSON.stringify(transferData, null, 2));
  
  console.log(`Balance: ${await erc20Transfer.balanceOf(publicKeys[100])}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
