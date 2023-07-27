import {ethers} from "hardhat";
import {RoyaltyAllowlist, RoyaltyAllowlist__factory} from "../typechain";


interface Env {
  ROYALTY_ALLOWLIST_ADDRESS: string;
  SEAPORT_ADDRESS: string;
}

// eslint-disable-next-line no-unused-vars
const DEVNET: Env = {
  ROYALTY_ALLOWLIST_ADDRESS: "0x9A48B1B27743d807331d06eCF0bFb15c06fDb58D",
  SEAPORT_ADDRESS: "0x41388404Efb7a68Fd31d75CEf71dF91e2BDBa2fb",
};

// eslint-disable-next-line no-unused-vars
const TESTNET: Env = {
  ROYALTY_ALLOWLIST_ADDRESS: "0x932038Fb3a308218C3BD2ee5979486897B80Fc28",
  SEAPORT_ADDRESS: "0x474989C4D25DD41B0B9b1ECb4643B9Fe25f83B19",
};

addseaport(TESTNET).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function addseaport(env: Env) {
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


  const contract = factory.attach(env.ROYALTY_ALLOWLIST_ADDRESS);

  const grantRegistrarRoleTransaction = await contract.grantRegistrarRole(
    deployer.address
  );
  console.log(`Transaction for grantRegistrarRole: ${grantRegistrarRoleTransaction.hash}`);
  await grantRegistrarRoleTransaction.wait(5);

  const role = await contract.REGISTRAR_ROLE();
  const hasRoleTransaction = await contract.hasRole(role, deployer.address);
  console.log(`Transaction for grantRegistrarRole: ${hasRoleTransaction}`);

  const addAddressToAllowlistTransaction = await contract.addAddressToAllowlist(
    [env.SEAPORT_ADDRESS]
  );

  console.log(
    `Transaction for addWalletToAllowlist: ${addAddressToAllowlistTransaction.hash}`
  );
}

