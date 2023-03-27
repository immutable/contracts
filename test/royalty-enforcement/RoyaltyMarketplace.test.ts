import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ImmutableERC721PermissionedMintable__factory,
  ImmutableERC721PermissionedMintable,
  RoyaltyAllowlist,
  RoyaltyAllowlist__factory,
  MockMarketplace__factory,
  MockMarketplace,
} from "../../typechain";

describe("Marketplace Royalty Enforcement", function () {
  this.timeout(300_000); // 5 min

  let erc721: ImmutableERC721PermissionedMintable;
  let royaltyAllowlist: RoyaltyAllowlist;
  let mockMarketplace: MockMarketplace;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let royaltyRecipient: SignerWithAddress;
  let buyer: SignerWithAddress;
  let seller: SignerWithAddress;

  const baseURI = "https://baseURI.com/";
  const contractURI = "https://contractURI.com";
  const name = "ERC721Preset";
  const symbol = "EP";
  const royalty = ethers.BigNumber.from("2000");

  before(async function () {
    // Retrieve accounts
    [owner, minter, registrar, royaltyRecipient, buyer, seller] = await ethers.getSigners();

    // Deploy ERC721 contract
    const erc721PresetFactory = (await ethers.getContractFactory(
      "ImmutableERC721PermissionedMintable"
    )) as ImmutableERC721PermissionedMintable__factory;

    erc721 = await erc721PresetFactory.deploy(
      owner.address,
      name,
      symbol,
      baseURI,
      contractURI,
      royaltyRecipient.address,
      royalty
    );
    
    // Deploy royalty Allowlist
    const royaltyAllowlistFactory = (await ethers.getContractFactory(
      "RoyaltyAllowlist"
    )) as RoyaltyAllowlist__factory;
    royaltyAllowlist = await royaltyAllowlistFactory.deploy(owner.address);

    // Deploy mock marketplace
    const mockMarketplaceFactory = (await ethers.getContractFactory(
      "MockMarketplace"
    )) as MockMarketplace__factory;
    mockMarketplace = await mockMarketplaceFactory.deploy(erc721.address);

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await royaltyAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });


  describe("Royalties", function () {

    it("Should set a valid royalty registry Allowlist", async function () {
      await erc721.connect(owner).setRoyaltyAllowlistRegistry(royaltyAllowlist.address);
      expect(await erc721.royaltyAllowlist()).to.be.equal(royaltyAllowlist.address);
    });

    it("Should allow a marketplace contract to be Allowlisted", async function () {
      await royaltyAllowlist.connect(registrar).addAddressToAllowlist([mockMarketplace.address]);
      expect(await royaltyAllowlist.isAllowlisted(mockMarketplace.address)).to.be.equal(true);
    });

    it("Should enforce royalties on a marketplace trade", async function () {
      // Get royalty info
      const salePrice = ethers.utils.parseEther("1");
      const tokenInfo = await erc721.royaltyInfo(2, salePrice);
      // Mint Nft to seller
      await erc721.connect(minter).mint(seller.address, 1);
      // Approve marketplace
      await erc721.connect(seller).setApprovalForAll(mockMarketplace.address, true);
      // Get pre-trade balances
      const recipientBal = await ethers.provider.getBalance(royaltyRecipient.address);
      const sellerBal = await ethers.provider.getBalance(seller.address);
      // Execute trade
      await mockMarketplace.connect(buyer).executeTransferRoyalties(seller.address, buyer.address, 1, salePrice, {value: salePrice});
      // Check if buyer recieved NFT
      expect(await erc721.tokenOfOwnerByIndex(buyer.address, 0)).to.be.equal(1);
      // Check if royalty recipient has increased balance newBal = oldBal + royaltyAmount
      expect(await ethers.provider.getBalance(royaltyRecipient.address)).to.equal(recipientBal.add(tokenInfo[1]));
      // Check if seller has increased balance newBal = oldBal + (salePrice - royaltyAmount)
      expect(await ethers.provider.getBalance(seller.address)).to.equal(sellerBal.add(salePrice.sub(tokenInfo[1])));
    });
  });
});
