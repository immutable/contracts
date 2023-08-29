import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ImmutableERC721, RoyaltyAllowlist } from "../../../typechain";
import { AllowlistFixture } from "../../utils/DeployHybridFixtures";

describe("ImmutableERC721", function () {
  let erc721: ImmutableERC721;
  let royaltyAllowlist: RoyaltyAllowlist;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let operator: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let chainId: number

  const baseURI = "https://baseURI.com/";
  const contractURI = "https://contractURI.com";
  const name = "ERC721Preset";
  const symbol = "EP";

  async function eoaSign(
    spender: String,
    tokenId: number,
    nonce: ethers.BigNumber,
    deadline: number
  ) {
    const typedData = {
      types: {
        Permit: [
          { name: "spender", type: "address" },
          { name: "tokenId", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      },
      primaryType: "Permit",
      domain: {
        name: await erc721.name(),
        version: "1",
        chainId: chainId,
        verifyingContract: erc721.address,
      },
      message: {
        spender,
        tokenId,
        nonce,
        deadline,
      },
    };
    const signature = await user._signTypedData(
      typedData.domain,
      { Permit: typedData.types.Permit },
      typedData.message
    );

    return signature;
  }

  before(async function () {
    // Retrieve accounts
    [owner, user, minter, registrar, operator] = await ethers.getSigners();

    // Get all required contracts
    ({ erc721, royaltyAllowlist } = await AllowlistFixture(owner));

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await royaltyAllowlist.connect(owner).grantRegistrarRole(registrar.address);
    chainId = await ethers.provider.getNetwork().then((n) => n.chainId);
  });

  describe("Permit", async function () {
    it("can use permits to approve spender", async function () {
      await erc721.connect(minter).mint(user.address, 1);
      expect(await erc721.balanceOf(user.address)).to.equal(1);

      const deadline = Math.round(Date.now() / 1000 + 7 * 24 * 60 * 60);
      const nonce = await erc721.nonces(1);
      expect(nonce).to.be.equal(0);

      const operatorAddress = await operator.getAddress()
      const signature = await eoaSign(
        operatorAddress,
        1,
        nonce,
        deadline
      );

      expect(await erc721.getApproved(1)).to.not.equal(
        await operator.getAddress()
      );

      await erc721
        .connect(operator)
        .permit(await operator.getAddress(), 1, deadline, signature);

      expect(await erc721.getApproved(1)).to.be.equal(await operator.getAddress());
    });

    it("reverts on permit if deadline has passed", async function () {
        await erc721.connect(minter).mint(user.address, 2);
  
        const deadline = Math.round(Date.now() / 1000 - 1 * 24 * 60 * 60);
        const nonce = await erc721.nonces(2);
  
        const operatorAddress = await operator.getAddress()
        const signature = await eoaSign(
          operatorAddress,
          2,
          nonce,
          deadline
        );
  
        await expect(
            erc721
              .connect(operator)
              .permit(await operator.getAddress(), 2, deadline, signature)
        ).to.be.revertedWith("PermitExpired");

        expect(await erc721.getApproved(2)).to.not.equal(await operator.getAddress());
      });
  });



});