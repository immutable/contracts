import hre from "hardhat";
import { Conduit__factory, ImmutableSeaport, ImmutableSignedZone } from "../../../typechain-types";

// Deploy the Immutable ecosystem contracts, returning the contract
// references
export async function deployImmutableContracts(serverSignerAddress: string): Promise<{
  immutableSeaport: ImmutableSeaport,
  immutableSignedZone: ImmutableSignedZone,
  conduitKey: string,
  conduitAddress: string
}> {
  const accounts = await hre.ethers.getSigners()
  const seaportConduitControllerContractFactory =
    await hre.ethers.getContractFactory("ConduitController");
  const seaportConduitControllerContract =
    await seaportConduitControllerContractFactory.deploy();
  await seaportConduitControllerContract.deployed();

  const readOnlyValidatorFactory = await hre.ethers.getContractFactory("ReadOnlyOrderValidator")
  const readOnlyValidatorContract = await readOnlyValidatorFactory.deploy();

  const validatorHelperFactory = await hre.ethers.getContractFactory("SeaportValidatorHelper")
  const validatorHelperContract = await validatorHelperFactory.deploy();

  const seaportValidatorFactory = await hre.ethers.getContractFactory("SeaportValidator")
  const seaportValidatorContract = await seaportValidatorFactory.deploy(
      readOnlyValidatorContract.address,
      validatorHelperContract.address,
      seaportConduitControllerContract.address
  )


  const immutableSignedZoneFactory = await hre.ethers.getContractFactory("ImmutableSignedZone");
  const immutableSignedZoneContract = await immutableSignedZoneFactory.deploy("ImmutableSignedZone", "", "");
  await immutableSignedZoneContract.deployed()

  const tx = await immutableSignedZoneContract.addSigner(serverSignerAddress)
  await tx.wait(1)

  // conduit key: The conduit key used to deploy the conduit. Note that the first twenty bytes of the conduit key must match the caller of this contract.
  const conduitKey = `${accounts[0].address}000000000000000000000000`;

  await (await seaportConduitControllerContract.createConduit(conduitKey, accounts[0].address)).wait(1);

  const  { conduit: conduitAddress } =
    await seaportConduitControllerContract.getConduit(conduitKey);

  const seaportContractFactory = await hre.ethers.getContractFactory(
    "ImmutableSeaport"
  );
  const seaportContract = await seaportContractFactory.deploy(
    seaportConduitControllerContract.address,
  );
  await seaportContract.deployed();

  // add ImmutableZone
  await(await seaportContract.connect(accounts[0]).setAllowedZone(immutableSignedZoneContract.address, true)).wait(1)
  await(await seaportConduitControllerContract.updateChannel(conduitAddress, seaportContract.address, true)).wait(1) 

  return {
    immutableSeaport: seaportContract,
    immutableSignedZone: immutableSignedZoneContract,
    conduitKey,
    conduitAddress,
  }
}
