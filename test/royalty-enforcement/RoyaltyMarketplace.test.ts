import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ImmutableERC721MintByID__factory,
  ImmutableERC721MintByID,
  OperatorAllowlist,
  OperatorAllowlist__factory,
  MockMarketplace__factory,
  MockMarketplace,
} from "../../typechain-types";

describe("Marketplace Royalty Enforcement", function () {
  this.timeout(300_000); // 5 min

  let erc721: ImmutableERC721MintByID;
  let operatorAllowlist: OperatorAllowlist;
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
    // Deploy operator Allowlist
    const operatorAllowlistFactory = (await ethers.getContractFactory(
      "OperatorAllowlist"
    )) as OperatorAllowlist__factory;
    operatorAllowlist = await operatorAllowlistFactory.deploy(owner.address);

    // Deploy ERC721 contract
    const erc721PresetFactory = (await ethers.getContractFactory(
      "ImmutableERC721MintByID"
    )) as ImmutableERC721MintByID__factory;

    erc721 = await erc721PresetFactory.deploy(
      owner.address,
      name,
      symbol,
      baseURI,
      contractURI,
      operatorAllowlist.address,
      royaltyRecipient.address,
      royalty
    );

    // Deploy mock marketplace
    const mockMarketplaceFactory = (await ethers.getContractFactory("MockMarketplace")) as MockMarketplace__factory;
    mockMarketplace = await mockMarketplaceFactory.deploy(erc721.address);

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await operatorAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Royalties", function () {
    it("Should allow a marketplace contract to be Allowlisted", async function () {
      await operatorAllowlist.connect(registrar).addAddressToAllowlist([mockMarketplace.address]);
      expect(await operatorAllowlist.isAllowlisted(mockMarketplace.address)).to.be.equal(true);
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
      await mockMarketplace.connect(buyer).executeTransferRoyalties(seller.address, buyer.address, 1, salePrice, {
        value: salePrice,
      });
      // Check if buyer recieved NFT
      expect(await erc721.ownerOf(1)).to.be.equal(buyer.address);
      // Check if royalty recipient has increased balance newBal = oldBal + royaltyAmount
      expect(await ethers.provider.getBalance(royaltyRecipient.address)).to.equal(recipientBal.add(tokenInfo[1]));
      // Check if seller has increased balance newBal = oldBal + (salePrice - royaltyAmount)
      expect(await ethers.provider.getBalance(seller.address)).to.equal(sellerBal.add(salePrice.sub(tokenInfo[1])));
    });
  });
});
