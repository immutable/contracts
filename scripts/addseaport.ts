import {ethers} from "hardhat";
import {RoyaltyAllowlist, RoyaltyAllowlist__factory} from "../typechain";


const ROYALTY_ALLOWLIST_DEV = "0x449b19eebbe656AE033B64fF408459F501F4A678"
const SEAPORT_DEV = "0x41388404Efb7a68Fd31d75CEf71dF91e2BDBa2fb"

const ROYALTY_ALLOWLIST_TESTNET = "0xE57661143ACef993BD2A0a6d01bb636625e6540B"
const SEAPORT_TESTNET = "0x45E23dA18804F99Cf67408AeBE85F67c958381Ff"

async function addseaport() {
  // get deployer
  const [deployer] = await ethers.getSigners();
  console.log("Running script with the account:", deployer.address);

  // check account balance
  console.log(
    "Account balance:",
    ethers.utils.formatEther(await deployer.getBalance())
  );

  // deploy MyERC721 contract
  const factory: RoyaltyAllowlist__factory = await ethers.getContractFactory(
    "RoyaltyAllowlist"
  );


  const contract = factory.attach(ROYALTY_ALLOWLIST_DEV);
  //
  // const tx1 = await contract.grantRegistrarRole(deployer.address)
  // console.log(`Transaction for grantRegistrarRole: ${tx1}`);


  // const role = await contract.REGISTRAR_ROLE()
  // const tx1 = await contract.hasRole(role, deployer.address)
  // console.log(`Transaction for grantRegistrarRole: ${tx1}`);

  const tx2 = await contract.addWalletToAllowlist(SEAPORT_DEV)
  // log deployed contract address
  console.log(`Transaction for addWalletToAllowlist: ${tx2}`);
}

addseaport().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
