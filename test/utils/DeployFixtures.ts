import { ethers, artifacts } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { defaultAbiCoder } from "ethers/lib/utils";
import {
  RoyaltyWhitelist__factory,
  RoyaltyWhitelist,
  ImmutableERC721PermissionedMintable__factory,
  ImmutableERC721PermissionedMintable,
  MockFactory__factory,
  MockFactory,
  MockMarketplace__factory,
  MockMarketplace,
} from "../../typechain";

export const whitelistFixture = async (owner: SignerWithAddress) => {
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

  // Mock wallet factory
  let MockFactory: MockFactory;
  const MockFactoryFactory = (await ethers.getContractFactory(
    "MockFactory"
  )) as MockFactory__factory;
  MockFactory = await MockFactoryFactory.deploy();

  // Whitelist registry
  let royaltyWhitelist: RoyaltyWhitelist;
  const RoyaltyWhitelist = (await ethers.getContractFactory(
    "RoyaltyWhitelist"
  )) as RoyaltyWhitelist__factory;
  royaltyWhitelist = await RoyaltyWhitelist.deploy(owner.address);

  // Mock market place
  let mockMarketPlace: MockMarketplace;
  const mockMarketplaceFactory = (await ethers.getContractFactory(
    "MockMarketplace"
  )) as MockMarketplace__factory;
  mockMarketPlace = await mockMarketplaceFactory.deploy(erc721.address);

  return {
    erc721,
    MockFactory,
    royaltyWhitelist,
    mockMarketPlace,
  };
};

export const walletSCFixture = async (
  scWallet: SignerWithAddress,
  erc721Addr: string,
  MockFactory: MockFactory
) => {
  // Encode the wallets constructor params
  const encodedParams = defaultAbiCoder
    .encode(["address", "address"], [scWallet.address, erc721Addr])
    .slice(2);

  // Calculate salt
  const salt = ethers.utils.keccak256("0x1234");

  // Get the artifact for bytecode
  const walletMockArtifact = await artifacts.readArtifact("MockWallet");

  // Append bytecode and constructor params
  const constructorByteCode = `${walletMockArtifact.bytecode}${encodedParams}`;

  // Calulate address of deployed contract
  const walletAddr = await MockFactory.computeAddress(
    salt,
    ethers.utils.keccak256(constructorByteCode)
  );

  // Deploy contract
  await MockFactory.connect(scWallet).deploy(salt, constructorByteCode);

  return walletAddr;
};

export const disguidedEOAFixture = async (
  erc721Addr: string,
  MockFactory: MockFactory,
  saltInput: string
) => {
  // Encode the wallets constructor params
  const encodedParams = defaultAbiCoder
    .encode(["address"], [erc721Addr])
    .slice(2);

  // Calculate salt
  const salt = ethers.utils.keccak256(saltInput);

  // Get the artifact for bytecode
  const mockDisguisedEOAArtifact = await artifacts.readArtifact("MockDisguisedEOA");

  // Append bytecode and constructor params
  const constructorByteCode = `${mockDisguisedEOAArtifact.bytecode}${encodedParams}`;

  // Calulate address of deployed contract
  const deployedAddr = await MockFactory.computeAddress(
    salt,
    ethers.utils.keccak256(constructorByteCode)
  );

  return {deployedAddr, salt, constructorByteCode};
};