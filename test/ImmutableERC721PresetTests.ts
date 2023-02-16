import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { ERC721Preset__factory, ERC721Preset } from "../typechain";

describe("ERC721 Preset Test Cases", function () {
  this.timeout(300_000); // 5 min

  let erc721 : ERC721Preset
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let minter: SignerWithAddress;

  const baseURI = "https://baseURI.com/";
  const contractURI = "https://contractURI.com";
  const name = "ERC721Preset";
  const symbol = "EP";

  before(async function () {
    // Retrieve accounts
    [owner, user, minter] = await ethers.getSigners();

    // Get contract
    const erc721PresetFactory = (await ethers.getContractFactory("ERC721Preset")) as ERC721Preset__factory;

    // Deploy ERC721 contract and intialize state
    erc721 = await erc721PresetFactory.deploy(owner.address, name, symbol, baseURI, contractURI);
    console.log("Deployed ERC721 to address: ", erc721.address);

    // Set up roles
    const minterRole = await erc721.MINTER_ROLE();
    await erc721.connect(owner).grantRole(minterRole, minter.address);
  });

  describe("Contract Deployment", function () { 
    it("Should set the admin role to the owner", async function () {
      const adminRole = await erc721.DEFAULT_ADMIN_ROLE();
      expect(await erc721.hasRole(adminRole, owner.address)).to.be.true;
    });

    it("Should set the name and symbol of the collection", async function () {
      expect(await erc721.name()).to.equal(name);
      expect(await erc721.symbol()).to.equal(symbol);
    });

    it("Should set collection URI", async function () {
      expect(await erc721.contractURI()).to.equal(contractURI);
    });

    it("Should set the contract owner", async function () {
      expect(await erc721.owner()).to.equal(owner.address);
    });
  });
  
  describe("Access Control", function () { 
    it("Should allow the default admin to transfer contract ownership", async function () {
      const adminRole = await erc721.DEFAULT_ADMIN_ROLE();
      await erc721.grantRole(adminRole, user.address)
      await expect(erc721.connect(owner).transferOwnership(user.address)).to.emit(erc721, "OwnershipTransferred").withArgs(owner.address, user.address);
      expect(await erc721.owner()).to.equal(user.address);
    });

    it("Should revert when caller doesn't have admin role", async function () {
      await expect(erc721.connect(minter).transferOwnership(owner.address)).to.be.revertedWith("AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
    });

    it("Should revert when caller isn't current owner, even with have admin role", async function () {
      await expect(erc721.connect(owner).transferOwnership(owner.address)).to.be.revertedWith("Caller must be current owner");
    });

    it("Should revert when new owner is already owner", async function () {
      await expect(erc721.connect(user).transferOwnership(user.address)).to.be.revertedWith("New owner is currently owner");
    });

    it("Should allow the owner to renounce ownership", async function () {
      const adminRole = await erc721.DEFAULT_ADMIN_ROLE();
      await erc721.grantRole(adminRole, ethers.constants.AddressZero)
      await erc721.connect(user).transferOwnership(ethers.constants.AddressZero)
      expect(await erc721.owner()).to.equal(ethers.constants.AddressZero);
    });
  });

  describe("Minting", function () { 
    const mintCount = 3;
    it("Should allow a member of the minter role to access permissioned mints", async function () {
      await erc721.connect(minter).permissionedMint(minter.address, mintCount);
      expect(await erc721.balanceOf(minter.address)).to.equal(mintCount);
      expect(await erc721.totalSupply()).to.equal(mintCount);
      // Verify tokenIds
      for (let i = 0; i < mintCount; i++) {
        expect(await erc721.tokenOfOwnerByIndex(minter.address, i)).to.equal(i+1);
      } 
      expect(await erc721.totalSupply()).to.equal(mintCount);
    });

    it("Should revert when caller does not have minter role", async function () {
      await expect(erc721.connect(user).permissionedMint(user.address, 1)).to.be.revertedWith("AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000");
    });

    it("Should mint no tokens with a mint amount of 0", async function () {
      await erc721.connect(minter).permissionedMint(minter.address, 0);
      expect(await erc721.totalSupply()).to.equal(mintCount);
    });
  });

  describe("Base URI and Token URI", function () { 
    it("Should return a non-empty tokenURI when the base URI is set", async function () {
      const tokenId = await erc721.totalSupply();
      expect(await erc721.tokenURI(tokenId)).to.equal(`${baseURI}${tokenId}`);
    });

    it("Should revert with a burnt tokenId", async function () {
      const tokenId = 1
      expect(await erc721.tokenURI(tokenId)).to.equal(`${baseURI}${tokenId}`);
      await erc721.connect(minter).burn(tokenId);
      await expect(erc721.tokenURI(tokenId)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("Should allow the default admin to update the base URI", async function () {
      await expect(erc721.connect(owner).setBaseURI("New Base URI")).to.emit(erc721, "BaseURIUpdated").withArgs(baseURI, "New Base URI")
    });

    it("Should revert with a non-existent tokenId", async function () {
      await expect(erc721.tokenURI(1001)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("Should revert with a caller does not have admin role", async function () {
      await expect(erc721.connect(minter).setBaseURI("New Base URI")).to.be.revertedWith("AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
    });

    it("Should return an empty token URI when the base URI is not set", async function () {
      await erc721.setBaseURI("")
      const tokenId = await erc721.totalSupply();
      expect(await erc721.tokenURI(tokenId)).to.equal("");
    });
  });

  describe("Contract URI", function () {
    it("Should allow the default admin to update the base URI", async function () {
      const newContractURI = "New Contract URI";
      await expect(erc721.connect(owner).setContractURI("New Contract URI")).to.emit(erc721, "ContractURIUpdated").withArgs(contractURI, "New Contract URI")
      expect(await erc721.contractURI()).to.equal(newContractURI);
    });

    it("Should revert with a caller does not have admin role", async function () {
      await expect(erc721.connect(minter).setContractURI("New Contract URI")).to.be.revertedWith("AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x0000000000000000000000000000000000000000000000000000000000000000");
    });
  });
});
