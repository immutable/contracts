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


  describe("Base URI and Token URI", function () {
    it("Should return a non-empty tokenURI when the base URI is set", async function () {
      const tokenId = 15;
      await erc721.connect(minter).mint(user.address, tokenId);
      expect(await erc721.tokenURI(tokenId)).to.equal(`${baseURI}${tokenId}`);
    });

    it("Should revert with a burnt tokenId", async function () {
      const tokenId = 20;
      await erc721.connect(user).burn(tokenId);
      await expect(erc721.tokenURI(tokenId)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("Should allow the default admin to update the base URI", async function () {
      const newBaseURI = "New Base URI";
      await erc721.connect(owner).setBaseURI(newBaseURI);
      expect(await erc721.baseURI()).to.equal(newBaseURI);
    });

    it("Should revert with a non-existent tokenId", async function () {
      await expect(erc721.tokenURI(1001)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("Should revert with a caller does not have admin role", async function () {
      await expect(erc721.connect(user).setBaseURI("New Base URI")).to.be.revertedWith(
        "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });

});
