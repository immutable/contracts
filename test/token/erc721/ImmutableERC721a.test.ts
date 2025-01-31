import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ImmutableERC721, OperatorAllowlist } from "../../../typechain-types";
import { AllowlistFixture } from "../../utils/DeployHybridFixtures";

describe("ImmutableERC721a", function () {
  let erc721: ImmutableERC721;
  let operatorAllowlist: OperatorAllowlist;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let user2: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;

  const baseURI = "https://baseURI.com/";
  const contractURI = "https://contractURI.com";
  const name = "ERC721Preset";
  const symbol = "EP";

  before(async function () {
    // Retrieve accounts
    [owner, user, minter, registrar, user2] = await ethers.getSigners();

    // Get all required contracts
    ({ erc721, operatorAllowlist } = await AllowlistFixture(owner));

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await operatorAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });



  it("Should allow batch minting of tokens by quantity", async function () {
    const qty = 5;
    const mintRequests = [{ to: user.address, quantity: qty }];
    const first = await erc721.mintBatchByQuantityThreshold();
    const originalBalance = await erc721.balanceOf(user.address);
    const originalSupply = await erc721.totalSupply();
    await erc721.connect(minter).mintBatchByQuantity(mintRequests);
    expect(await erc721.balanceOf(user.address)).to.equal(originalBalance.add(qty));
    expect(await erc721.totalSupply()).to.equal(originalSupply.add(qty));
    for (let i = 0; i < qty; i++) {
      expect(await erc721.ownerOf(first.add(i))).to.equal(user.address);
    }
  });

  it("Should allow safe batch minting of tokens by quantity", async function () {
    const qty = 5;
    const mintRequests = [{ to: user2.address, quantity: qty }];
    const first = await erc721.mintBatchByQuantityThreshold();
    const originalBalance = await erc721.balanceOf(user2.address);
    const originalSupply = await erc721.totalSupply();
    await erc721.connect(minter).safeMintBatchByQuantity(mintRequests);
    expect(await erc721.balanceOf(user2.address)).to.equal(originalBalance.add(qty));
    expect(await erc721.totalSupply()).to.equal(originalSupply.add(qty));
    for (let i = 5; i < 10; i++) {
      expect(await erc721.ownerOf(first.add(i))).to.equal(user2.address);
    }
  });

  it("Should safe mint by quantity", async function () {
    const qty = 5;
    const first = await erc721.mintBatchByQuantityThreshold();
    const originalBalance = await erc721.balanceOf(user2.address);
    const originalSupply = await erc721.totalSupply();
    await erc721.connect(minter).safeMintByQuantity(user2.address, qty);
    expect(await erc721.balanceOf(user2.address)).to.equal(originalBalance.add(qty));
    expect(await erc721.totalSupply()).to.equal(originalSupply.add(qty));
    for (let i = 10; i < 15; i++) {
      expect(await erc721.ownerOf(first.add(i))).to.equal(user2.address);
    }
  });


  it("Should allow owner or approved to burn a batch of mixed ID/PSI tokens", async function () {
    const originalBalance = await erc721.balanceOf(user.address);
    const originalSupply = await erc721.totalSupply();
    const first = await erc721.mintBatchByQuantityThreshold();
    const batch = [3, 4, first.toString(), first.add(1).toString()];
    await erc721.connect(user).burnBatch(batch);
    expect(await erc721.balanceOf(user.address)).to.equal(originalBalance.sub(batch.length));
    expect(await erc721.totalSupply()).to.equal(originalSupply.sub(batch.length));
  });

  it("Should prevent not approved to burn a batch of tokens", async function () {
    const first = await erc721.mintBatchByQuantityThreshold();
    await expect(erc721.connect(minter).burnBatch([first.add(2), first.add(3)]))
      .to.be.revertedWith("IImmutableERC721NotOwnerOrOperator")
      .withArgs(first.add(2));
  });

    it("Should revert if minting by id with id above threshold", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      const mintRequests = [{ to: user.address, tokenIds: [first] }];
      await expect(erc721.connect(minter).mintBatch(mintRequests))
        .to.be.revertedWith("IImmutableERC721IDAboveThreshold")
        .withArgs(first);
    });


  describe("exists", async function () {
    it("verifies valid tokens minted by quantity", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      expect(await erc721.exists(first.add(3))).to.equal(true);
    });

    it("verifies valid tokens minted by id", async function () {
      expect(await erc721.exists(8)).to.equal(true);
    });

    it("verifies invalid tokens", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      expect(await erc721.exists(first.add(15))).to.equal(false);
    });
  });

});
