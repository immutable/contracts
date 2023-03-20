import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { whitelistFixture, walletSCFixture } from "../utils/DeployFixtures";
import {
  ImmutableERC721PermissionedMintable,
  MockMarketplace,
  MockFactory,
  RoyaltyWhitelist,
} from "../../typechain";

describe("Royalty Enforcement Test Cases", function () {
  this.timeout(300_000); // 5 min

  let owner: SignerWithAddress;
  let registrar: SignerWithAddress;
  let scWallet: SignerWithAddress;
  let erc721: ImmutableERC721PermissionedMintable;
  let MockFactory: MockFactory;
  let royaltyWhitelist: RoyaltyWhitelist;
  let mockMarketPlace: MockMarketplace;

  before(async function () {
    [owner, registrar, scWallet] =
      await ethers.getSigners();

    // Deploy all required contracts
    ({ erc721, MockFactory, royaltyWhitelist, mockMarketPlace } =
      await whitelistFixture(owner));

    // Grant registrar role
    await royaltyWhitelist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Contract Deployment", function () {
    it("Should set the admin role to the owner", async function () {
      const adminRole = await royaltyWhitelist.DEFAULT_ADMIN_ROLE();
      expect(await royaltyWhitelist.hasRole(adminRole, owner.address)).to.be
        .true;
    });
  });

  describe("Interface Support", function () {
    it("Should support the royalty whitelist interface", async function () {
      expect(await royaltyWhitelist.supportsInterface("0x13f44d10")).to.be.true;
    });
  });

  describe("Access Control", function () {
    it("Should limit whitelist add and remove functionality to registrar roles", async function () {
      const revertStr =
        "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000";
      // addAddressToWhitelist
      await expect(
        royaltyWhitelist
          .connect(owner)
          .addAddressToWhitelist(royaltyWhitelist.address)
      ).to.be.revertedWith(revertStr);
      // removeAddressFromWhitelist
      await expect(
        royaltyWhitelist
          .connect(owner)
          .removeAddressFromWhitelist(royaltyWhitelist.address)
      ).to.be.revertedWith(revertStr);
      // addBytecodeToWhitelist
      await expect(
        royaltyWhitelist
          .connect(owner)
          .addBytecodeToWhitelist(ethers.utils.keccak256("0x1234"))
      ).to.be.revertedWith(revertStr);
      // removeBytecodeFromWhitelist
      await expect(
        royaltyWhitelist
          .connect(owner)
          .removeBytecodeFromWhitelist(ethers.utils.keccak256("0x1234"))
      ).to.be.revertedWith(revertStr);
    });
  });

  describe("Whitelisting of Bytecode and Addresses", function () {
    it("Should add the bytecode of a deployed CREATE2 contract to the whitelist and then remove it from the whitelist", async function () {
      // Deploy SC wallet and get deployed address
      const deployedAddr = await walletSCFixture(scWallet, erc721.address, MockFactory);
      // Retrieve the bytecode at the deployed address
      const deployedBytecode = await ethers.provider.getCode(deployedAddr);

      // Add bytecode
      await expect(
        royaltyWhitelist
          .connect(registrar)
          .addBytecodeToWhitelist(ethers.utils.keccak256(deployedBytecode))
      )
        .to.emit(royaltyWhitelist, "BytecodeWhitelistChanged")
        .withArgs(ethers.utils.keccak256(deployedBytecode), true);

      expect(await royaltyWhitelist.isAddressWhitelisted(deployedAddr)).to.be
        .true;

      // Remove bytecode
      await expect(
        royaltyWhitelist
          .connect(registrar)
          .removeBytecodeFromWhitelist(ethers.utils.keccak256(deployedBytecode))
      )
        .to.emit(royaltyWhitelist, "BytecodeWhitelistChanged")
        .withArgs(ethers.utils.keccak256(deployedBytecode), false);

      expect(await royaltyWhitelist.isAddressWhitelisted(deployedAddr)).to.be
        .false;
    });

    it("Should add the address of a contract to the whitelist and then remove it from the whitelist", async function () {
      // Add address
      await expect(
        royaltyWhitelist
          .connect(registrar)
          .addAddressToWhitelist(mockMarketPlace.address)
      )
        .to.emit(royaltyWhitelist, "AddressWhitelistChanged")
        .withArgs(mockMarketPlace.address, true);

      expect(
        await royaltyWhitelist.isAddressWhitelisted(mockMarketPlace.address)
      ).to.be.true;

      // Remove address
      await expect(
        royaltyWhitelist
          .connect(registrar)
          .removeAddressFromWhitelist(mockMarketPlace.address)
      )
        .to.emit(royaltyWhitelist, "AddressWhitelistChanged")
        .withArgs(mockMarketPlace.address, false);

      expect(
        await royaltyWhitelist.isAddressWhitelisted(mockMarketPlace.address)
      ).to.be.false;
    });
  });
});
