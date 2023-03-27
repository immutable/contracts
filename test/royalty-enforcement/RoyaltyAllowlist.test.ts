import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { walletSCFixture, AllowlistFixture } from "../utils/DeployFixtures";
import {
  ImmutableERC721PermissionedMintable,
  MockMarketplace,
  MockFactory,
  RoyaltyAllowlist,
  MockWalletFactory,
} from "../../typechain";
import proxyArtfiact from "../../test/utils/proxyArtifact.json";

describe("Royalty Enforcement Test Cases", function () {
  this.timeout(300_000); // 5 min

  let owner: SignerWithAddress;
  let registrar: SignerWithAddress;
  let scWallet: SignerWithAddress;
  let erc721: ImmutableERC721PermissionedMintable;
  let walletFactory: MockWalletFactory;
  let royaltyAllowlist: RoyaltyAllowlist;
  let marketPlace: MockMarketplace;

  before(async function () {
    [owner, registrar, scWallet] = await ethers.getSigners();

    // Deploy all required contracts
    ({ erc721, walletFactory, royaltyAllowlist, marketPlace } =
      await AllowlistFixture(owner));

    // Grant registrar role
    await royaltyAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Contract Deployment", function () {
    it("Should set the admin role to the owner", async function () {
      const adminRole = await royaltyAllowlist.DEFAULT_ADMIN_ROLE();
      expect(await royaltyAllowlist.hasRole(adminRole, owner.address)).to.be
        .true;
    });
  });

  describe("Interface Support", function () {
    it("Should support the royalty Allowlist interface", async function () {
      expect(await royaltyAllowlist.supportsInterface("0x05a3b809")).to.be.true;
    });
  });

  describe("Access Control", function () {
    it("Should limit Allowlist add and remove functionality to registrar roles", async function () {
      const revertStr =
        "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000";
      // addAddressToAllowlist
      await expect(
        royaltyAllowlist
          .connect(owner)
          .addAddressToAllowlist([royaltyAllowlist.address])
      ).to.be.revertedWith(revertStr);
      // removeAddressFromAllowlist
      await expect(
        royaltyAllowlist
          .connect(owner)
          .removeAddressFromAllowlist([royaltyAllowlist.address])
      ).to.be.revertedWith(revertStr);
      // addBytecodeToAllowlist
      await expect(
        royaltyAllowlist
          .connect(owner)
          .addWalletToAllowlist(royaltyAllowlist.address)
      ).to.be.revertedWith(revertStr);
      // removeBytecodeFromAllowlist
      await expect(
        royaltyAllowlist
          .connect(owner)
          .removeWalletFromAllowlist(royaltyAllowlist.address)
      ).to.be.revertedWith(revertStr);
    });
  });

  describe("Allowlisting of Addresses and Smart Contract Wallets", function () {
    it("Should add the bytecode of a deployed smart contract wallet's byte code and the implementation contract address to the Allowlist and then remove it from the Allowlist", async function () {
      // Deploy the wallet fixture
      const { deployedAddr, moduleAddress } = await walletSCFixture(
        scWallet,
        walletFactory
      );

      // Verify implementation is set
      const Proxy = ethers.getContractFactory(
        proxyArtfiact.abi,
        proxyArtfiact.bytecode
      );
      const proxy = (await Proxy).attach(deployedAddr);
      expect(await proxy.PROXY_getImplementation()).to.be.equal(moduleAddress);

      // Get the deployed bytecode
      const deployedBytecode = await ethers.provider.getCode(deployedAddr);

      // Add the wallet to the allow list. This will add the wallets bytecode and the implementation address
      await expect(
        royaltyAllowlist.connect(registrar).addWalletToAllowlist(deployedAddr)
      )
        .to.emit(royaltyAllowlist, "WalletAllowlistChanged")
        .withArgs(ethers.utils.keccak256(deployedBytecode), deployedAddr, true);


      expect(await royaltyAllowlist.isAllowlisted(deployedAddr)).to.be.true;

      // Remove the wallet from the allowlist
      await expect(
        royaltyAllowlist.connect(registrar).removeWalletFromAllowlist(deployedAddr)
      )
        .to.emit(royaltyAllowlist, "WalletAllowlistChanged")
        .withArgs(ethers.utils.keccak256(deployedBytecode), deployedAddr, false);

      expect(await royaltyAllowlist.isAllowlisted(deployedAddr)).to.be.false;
    });

    it("Should add the address of a contract to the Allowlist and then remove it from the Allowlist", async function () {
      // Add address
      await expect(
        royaltyAllowlist
          .connect(registrar)
          .addAddressToAllowlist([marketPlace.address])
      )
        .to.emit(royaltyAllowlist, "AddressAllowlistChanged")
        .withArgs(marketPlace.address, true);

      expect(await royaltyAllowlist.isAllowlisted(marketPlace.address)).to.be
        .true;

      // Remove address
      await expect(
        royaltyAllowlist
          .connect(registrar)
          .removeAddressFromAllowlist([marketPlace.address])
      )
        .to.emit(royaltyAllowlist, "AddressAllowlistChanged")
        .withArgs(marketPlace.address, false);

      expect(await royaltyAllowlist.isAllowlisted(marketPlace.address)).to.be
        .false;
    });

    it("Should not allowlist smart contract wallets with the same bytecode but a different implementation address", async function () {
      // Deploy with different module
      const salt = ethers.utils.keccak256("0x4567");
      await walletFactory.connect(scWallet).deploy(erc721.address, salt);
      const deployedAddr = await walletFactory.getAddress(
        erc721.address,
        salt
      );

      expect(await royaltyAllowlist.isAllowlisted(deployedAddr)).to.be
      .false;
    });
  });
});
