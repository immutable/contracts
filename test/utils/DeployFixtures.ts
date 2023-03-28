import { ethers, artifacts } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { defaultAbiCoder } from "ethers/lib/utils";
import {
  RoyaltyAllowlist__factory,
  RoyaltyAllowlist,
  ImmutableERC721PermissionedMintable__factory,
  ImmutableERC721PermissionedMintable,
  MockFactory__factory,
  MockFactory,
  MockMarketplace__factory,
  MockMarketplace,
  MockWalletFactory,
  MockWalletFactory__factory,
} from "../../typechain";

// Helper function to deploy all required contracts for Allowlist testing. Deploys:
// - ERC721
// - Mock factory
// - Mock wallet factory
// - Allowlist registry
// - Mock market place
export const AllowlistFixture = async (owner: SignerWithAddress) => {
  // ERC721
  let erc721: ImmutableERC721PermissionedMintable;
  const erc721PresetFactory = (await ethers.getContractFactory(
    "ImmutableERC721PermissionedMintable"
  )) as ImmutableERC721PermissionedMintable__factory;
  erc721 = await erc721PresetFactory.deploy(
    owner.address,
    "ERC721Preset",
    "EP",
    "https://baseURI.com/",
    "https://contractURI.com",
    owner.address,
    ethers.BigNumber.from("200")
  );

  // Mock Wallet factory
  const WalletFactory = (await ethers.getContractFactory(
    "MockWalletFactory"
  )) as MockWalletFactory__factory;
  const walletFactory = await WalletFactory.deploy();

  // Mock  factory
  const Factory = (await ethers.getContractFactory(
    "MockFactory"
  )) as MockFactory__factory;
  const factory = await Factory.deploy();

  // Allowlist registry
  let royaltyAllowlist: RoyaltyAllowlist;
  const RoyaltyAllowlist = (await ethers.getContractFactory(
    "RoyaltyAllowlist"
  )) as RoyaltyAllowlist__factory;
  royaltyAllowlist = await RoyaltyAllowlist.deploy(owner.address);

  // Mock market place
  let marketPlace: MockMarketplace;
  const mockMarketplaceFactory = (await ethers.getContractFactory(
    "MockMarketplace"
  )) as MockMarketplace__factory;
  marketPlace = await mockMarketplaceFactory.deploy(erc721.address);

  return {
    erc721,
    walletFactory,
    factory,
    royaltyAllowlist,
    marketPlace,
  };
};

// Helper function to deploy SC wallet via CREATE2 and return deterministic address
export const walletSCFixture = async (
  walletDeployer: SignerWithAddress,
  mockWalletFactory: MockWalletFactory
) => {
  // Deploy the implementation contract or wallet module
  const Module = await ethers.getContractFactory(
   "MockWallet"
  );
  
  const module = await Module.connect(walletDeployer).deploy();

  const moduleAddress = module.address

  // Calculate salt
  const salt = ethers.utils.keccak256("0x1234");

  // Deploy wallet via factory
  await mockWalletFactory
    .connect(walletDeployer)
    .deploy(module.address, salt);
  

  const deployedAddr = await mockWalletFactory.getAddress(module.address, salt);
  
  return {deployedAddr, moduleAddress};
};

// Helper function to return required artifacts to deploy disguised EOA via CREATE2
export const disguidedEOAFixture = async (
  erc721Addr: string,
  MockFactory: MockFactory,
  saltInput: string
) => {
  // Encode the constructor params
  const encodedParams = defaultAbiCoder
    .encode(["address"], [erc721Addr])
    .slice(2);

  // Calculate salt
  const salt = ethers.utils.keccak256(saltInput);

  // Get the artifact for bytecode
  const mockDisguisedEOAArtifact = await artifacts.readArtifact(
    "MockDisguisedEOA"
  );

  // Append bytecode and constructor params
  const constructorByteCode = `${mockDisguisedEOAArtifact.bytecode}${encodedParams}`;

  // Calulate address of deployed contract
  const deployedAddr = await MockFactory.computeAddress(
    salt,
    ethers.utils.keccak256(constructorByteCode)
  );

  return { deployedAddr, salt, constructorByteCode };
};
