import {ethers} from "hardhat";
import {RoyaltyAllowlist, RoyaltyAllowlist__factory} from "../typechain";

async function deploy() {
  // get deployer
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // check account balance
  console.log(
    "Account balance:",
    ethers.utils.formatEther(await deployer.getBalance())
  );

  // deploy MyERC721 contract
  const RoyaltyAllowList: RoyaltyAllowlist__factory = await ethers.getContractFactory(
    "RoyaltyAllowlist"
  );
  const contract: RoyaltyAllowlist = await RoyaltyAllowList.connect(deployer).deploy(
    deployer.address, // owner
  );
  await contract.deployed();

  // log deployed contract address
  console.log(`RoyaltyAllowlist contract deployed to ${contract.address}`);
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
