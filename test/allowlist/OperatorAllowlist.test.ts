import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { walletSCFixture, RegularAllowlistFixture } from "../utils/DeployRegularFixtures";
import { ImmutableERC721MintByID, MockMarketplace, OperatorAllowlist, MockWalletFactory } from "../../typechain";
import proxyArtfiact from "../utils/proxyArtifact.json";

describe("Royalty Enforcement Test Cases", function () {
  this.timeout(300_000); // 5 min

  let owner: SignerWithAddress;
  let registrar: SignerWithAddress;
  let scWallet: SignerWithAddress;
  let erc721: ImmutableERC721MintByID;
  let walletFactory: MockWalletFactory;
  let operatorAllowlist: OperatorAllowlist;
  let marketPlace: MockMarketplace;

  before(async function () {
    [owner, registrar, scWallet] = await ethers.getSigners();

    // Deploy all required contracts
    ({ erc721, walletFactory, operatorAllowlist, marketPlace } = await RegularAllowlistFixture(owner));

    // Grant registrar role
    await operatorAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Contract Deployment", function () {
    it("Should set the admin role to the owner", async function () {
      const adminRole = await operatorAllowlist.DEFAULT_ADMIN_ROLE();
      expect(await operatorAllowlist.hasRole(adminRole, owner.address)).to.be.equal(true);
    });
  });

  describe("Interface Support", function () {
    it("Should support the royalty Allowlist interface", async function () {
      expect(await operatorAllowlist.supportsInterface("0x05a3b809")).to.be.equal(true);
    });
  });

  describe("Access Control", function () {
    it("Should limit Allowlist add and remove functionality to registrar roles", async function () {
      const revertStr =
        "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x5245474953545241525f524f4c45000000000000000000000000000000000000";
      // addAddressToAllowlist
      await expect(
        operatorAllowlist.connect(owner).addAddressToAllowlist([operatorAllowlist.address])
      ).to.be.revertedWith(revertStr);
      // removeAddressFromAllowlist
      await expect(
        operatorAllowlist.connect(owner).removeAddressFromAllowlist([operatorAllowlist.address])
      ).to.be.revertedWith(revertStr);
      // addBytecodeToAllowlist
      await expect(operatorAllowlist.connect(owner).addWalletToAllowlist(operatorAllowlist.address)).to.be.revertedWith(
        revertStr
      );
      // removeBytecodeFromAllowlist
      await expect(
        operatorAllowlist.connect(owner).removeWalletFromAllowlist(operatorAllowlist.address)
      ).to.be.revertedWith(revertStr);
    });
  });

  describe("Allowlisting of Addresses and Smart Contract Wallets", function () {
    it("Should add the bytecode of a deployed smart contract wallet's byte code and the implementation contract address to the Allowlist and then remove it from the Allowlist", async function () {
      // Deploy the wallet fixture
      const { deployedAddr, moduleAddress } = await walletSCFixture(scWallet, walletFactory);

      // Verify implementation is set
      const Proxy = ethers.getContractFactory(proxyArtfiact.abi, proxyArtfiact.bytecode);
      const proxy = (await Proxy).attach(deployedAddr);
      expect(await proxy.PROXY_getImplementation()).to.be.equal(moduleAddress);

      // Get the deployed bytecode
      const deployedBytecode = await ethers.provider.getCode(deployedAddr);

      // Add the wallet to the allow list. This will add the wallets bytecode and the implementation address
      await expect(operatorAllowlist.connect(registrar).addWalletToAllowlist(deployedAddr))
        .to.emit(operatorAllowlist, "WalletAllowlistChanged")
        .withArgs(ethers.utils.keccak256(deployedBytecode), deployedAddr, true);

      expect(await operatorAllowlist.isAllowlisted(deployedAddr)).to.be.equal(true);

      // Remove the wallet from the allowlist
      await expect(operatorAllowlist.connect(registrar).removeWalletFromAllowlist(deployedAddr))
        .to.emit(operatorAllowlist, "WalletAllowlistChanged")
        .withArgs(ethers.utils.keccak256(deployedBytecode), deployedAddr, false);

      expect(await operatorAllowlist.isAllowlisted(deployedAddr)).to.be.equal(false);
    });

    it("Should add the address of a contract to the Allowlist and then remove it from the Allowlist", async function () {
      // Add address
      await expect(operatorAllowlist.connect(registrar).addAddressToAllowlist([marketPlace.address]))
        .to.emit(operatorAllowlist, "AddressAllowlistChanged")
        .withArgs(marketPlace.address, true);

      expect(await operatorAllowlist.isAllowlisted(marketPlace.address)).to.be.equal(true);

      // Remove address
      await expect(operatorAllowlist.connect(registrar).removeAddressFromAllowlist([marketPlace.address]))
        .to.emit(operatorAllowlist, "AddressAllowlistChanged")
        .withArgs(marketPlace.address, false);

      expect(await operatorAllowlist.isAllowlisted(marketPlace.address)).to.be.equal(false);
    });

    it("Should not allowlist smart contract wallets with the same bytecode but a different implementation address", async function () {
      // Deploy with different module
      const salt = ethers.utils.keccak256("0x4567");
      await walletFactory.connect(scWallet).deploy(erc721.address, salt);
      const deployedAddr = await walletFactory.getAddress(erc721.address, salt);

      expect(await operatorAllowlist.isAllowlisted(deployedAddr)).to.be.equal(false);
    });
  });
});
