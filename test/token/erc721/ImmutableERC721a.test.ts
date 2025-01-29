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


  describe("Minting and burning", function () {
    it("Should not allow owner or approved to burn a token when specifying the incorrect owner", async function () {
      await expect(erc721.connect(user).safeBurn(owner.address, 5))
        .to.be.revertedWith("IImmutableERC721MismatchedTokenOwner")
        .withArgs(5, user.address);
    });

    it("Should allow owner or approved to safely burn a token when specifying the correct owner", async function () {
      const originalBalance = await erc721.balanceOf(user.address);
      const originalSupply = await erc721.totalSupply();
      await erc721.connect(user).safeBurn(user.address, 5);
      expect(await erc721.balanceOf(user.address)).to.equal(originalBalance.sub(1));
      expect(await erc721.totalSupply()).to.equal(originalSupply.sub(1));
    });

    it("Should not allow owner or approved to burn a batch of tokens when specifying the incorrect owners", async function () {
      const burns = [
        {
          owner: user.address,
          tokenIds: [12, 13, 14],
        },
        {
          owner: owner.address,
          tokenIds: [9, 10, 11],
        },
      ];
      await expect(erc721.connect(user).safeBurnBatch(burns))
        .to.be.revertedWith("IImmutableERC721MismatchedTokenOwner")
        .withArgs(12, owner.address);
    });

    it("Should allow owner or approved to safely burn a batch of tokens when specifying the correct owners", async function () {
      const originalUserBalance = await erc721.balanceOf(user.address);
      const originalOwnerBalance = await erc721.balanceOf(owner.address);
      const originalSupply = await erc721.totalSupply();

      // Set approval for owner to burn these tokens from user.
      await erc721.connect(user).approve(owner.address, 9);
      await erc721.connect(user).approve(owner.address, 10);
      await erc721.connect(user).approve(owner.address, 11);

      const burns = [
        {
          owner: owner.address,
          tokenIds: [12, 13, 14],
        },
        {
          owner: user.address,
          tokenIds: [9, 10, 11],
        },
      ];
      await erc721.connect(owner).safeBurnBatch(burns);
      expect(await erc721.balanceOf(user.address)).to.equal(originalUserBalance.sub(3));
      expect(await erc721.balanceOf(owner.address)).to.equal(originalOwnerBalance.sub(3));
      expect(await erc721.totalSupply()).to.equal(originalSupply.sub(6));
    });

    it("Should prevent not approved to burn a batch of tokens", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      await expect(erc721.connect(minter).burnBatch([first.add(2), first.add(3)]))
        .to.be.revertedWith("IImmutableERC721NotOwnerOrOperator")
        .withArgs(first.add(2));
    });

    // TODO: are we happy to allow minting burned tokens?
    it("Should prevent minting burned tokens", async function () {
      const mintRequests = [{ to: user.address, tokenIds: [1, 2] }];
      await expect(erc721.connect(minter).mintBatch(mintRequests))
        .to.be.revertedWith("IImmutableERC721TokenAlreadyBurned")
        .withArgs(1);
    });

    it("Should revert if minting by id with id above threshold", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      const mintRequests = [{ to: user.address, tokenIds: [first] }];
      await expect(erc721.connect(minter).mintBatch(mintRequests))
        .to.be.revertedWith("IImmutableERC721IDAboveThreshold")
        .withArgs(first);
    });
  });
});
