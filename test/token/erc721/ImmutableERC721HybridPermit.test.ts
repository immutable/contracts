import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ImmutableERC721, OperatorAllowlist, MockEIP1271Wallet } from "../../../typechain";
import { AllowlistFixture } from "../../utils/DeployHybridFixtures";
import { BigNumberish } from "ethers";

describe("ImmutableERC721Permit", function () {
  let erc721: ImmutableERC721;
  let operatorAllowlist: OperatorAllowlist;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let operator: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let chainId: number;
  let eip1271Wallet: MockEIP1271Wallet;

  async function eoaSign(
    signer: SignerWithAddress,
    spender: String,
    tokenId: BigNumberish,
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
        chainId,
        verifyingContract: erc721.address,
      },
      message: {
        spender,
        tokenId,
        nonce,
        deadline,
      },
    };

    const signature = await signer._signTypedData(
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
    ({ erc721, operatorAllowlist, eip1271Wallet } = await AllowlistFixture(owner));

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await operatorAllowlist.connect(owner).grantRegistrarRole(registrar.address);
    chainId = await ethers.provider.getNetwork().then((n) => n.chainId);
  });

  describe("Interfaces", async function () {
    it("implements the erc4494 interface", async function () {
      expect(await erc721.supportsInterface("0x5604e225")).to.equal(true);
    });
  });

  describe("EOA Permit", async function () {
    it("can use permits to approve spender on token minted by ID", async function () {
      await erc721.connect(minter).mint(user.address, 1);

      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const nonce = await erc721.nonces(1);
      expect(nonce).to.be.equal(0);

      const operatorAddress = await operator.getAddress();
      const signature = await eoaSign(user, operatorAddress, 1, nonce, deadline);

      expect(await erc721.getApproved(1)).to.not.equal(operatorAddress);
      console.log("operator: ", operatorAddress);

      await erc721.connect(operator).permit(operatorAddress, 1, deadline, signature);

      expect(await erc721.getApproved(1)).to.be.equal(operatorAddress);
    });

    it("can use permits to approve spender on token minted by quantity", async function () {
      await erc721.connect(minter).mintByQuantity(user.address, 1);
      const first = await erc721.mintBatchByQuantityThreshold();

      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const nonce = await erc721.nonces(first);
      expect(nonce).to.be.equal(0);

      const operatorAddress = await operator.getAddress();
      const signature = await eoaSign(user, operatorAddress, first, nonce, deadline);

      expect(await erc721.getApproved(first)).to.not.equal(operatorAddress);

      await erc721.connect(operator).permit(operatorAddress, first, deadline, signature);

      expect(await erc721.getApproved(first)).to.be.equal(operatorAddress);
    });

    it("reverts on permit if deadline has passed", async function () {
      await erc721.connect(minter).mint(user.address, 2);

      const deadline = Math.round(Date.now() / 1000 - 24 * 60 * 60);
      const nonce = await erc721.nonces(2);

      const operatorAddress = await operator.getAddress();
      const signature = await eoaSign(user, operatorAddress, 2, nonce, deadline);

      await expect(erc721.connect(operator).permit(operatorAddress, 2, deadline, signature)).to.be.revertedWith(
        "PermitExpired"
      );

      expect(await erc721.getApproved(2)).to.not.equal(operatorAddress);
    });

    it("allows approved operators to create permits on behalf of token owner", async function () {
      await erc721.connect(minter).mint(user.address, 3);

      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const nonce = await erc721.nonces(3);
      expect(nonce).to.be.equal(0);
      const ownerAddr = await owner.getAddress();
      const operatorAddress = await operator.getAddress();
      const signature = await eoaSign(owner, operatorAddress, 3, nonce, deadline);

      await expect(erc721.connect(operator).permit(operatorAddress, 3, deadline, signature)).to.be.revertedWith(
        "InvalidSignature"
      );

      expect(await erc721.getApproved(3)).to.not.equal(operatorAddress);

      await erc721.connect(user).approve(ownerAddr, 3);

      await erc721.connect(operator).permit(operatorAddress, 3, deadline, signature);

      expect(await erc721.getApproved(3)).to.be.equal(operatorAddress);
    });

    it("can not use a permit after a transfer due to bad nonce", async function () {
      await erc721.connect(minter).mint(user.address, 4);
      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const operatorAddress = await operator.getAddress();
      let nonce = await erc721.nonces(4);
      expect(nonce).to.be.equal(0);
      const signature = await eoaSign(user, operatorAddress, 4, nonce, deadline);

      await erc721
        .connect(user)
        ["safeTransferFrom(address,address,uint256)"](await user.getAddress(), await owner.getAddress(), 4);

      nonce = await erc721.nonces(4);
      expect(nonce).to.be.equal(1);

      await erc721
        .connect(owner)
        ["safeTransferFrom(address,address,uint256)"](await owner.getAddress(), await user.getAddress(), 4);
      nonce = await erc721.nonces(4);
      expect(nonce).to.be.equal(2);

      await expect(erc721.connect(operator).permit(operatorAddress, 4, deadline, signature)).to.be.revertedWith(
        "InvalidSignature"
      );
    });

    it("can not use a permit after a transfer of token minted by id due to bad owner", async function () {
      await erc721.connect(minter).mint(user.address, 5);
      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const operatorAddress = await operator.getAddress();

      await erc721
        .connect(user)
        ["safeTransferFrom(address,address,uint256)"](await user.getAddress(), await owner.getAddress(), 5);

      const nonce = await erc721.nonces(5);
      expect(nonce).to.be.equal(1);

      const signature = await eoaSign(user, operatorAddress, 5, nonce, deadline);

      await expect(erc721.connect(operator).permit(operatorAddress, 5, deadline, signature)).to.be.revertedWith(
        "InvalidSignature"
      );
    });

    it("can not use a permit after a transfer of token minted by quantity due to bad owner", async function () {
      await erc721.connect(minter).mintByQuantity(user.address, 1);
      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const operatorAddress = await operator.getAddress();
      const tokenId = (await erc721.mintBatchByQuantityThreshold()).add(1);

      await erc721
        .connect(user)
        ["safeTransferFrom(address,address,uint256)"](await user.getAddress(), await owner.getAddress(), tokenId);

      const nonce = await erc721.nonces(tokenId);
      expect(nonce).to.be.equal(1);

      const signature = await eoaSign(user, operatorAddress, tokenId, nonce, deadline);

      await expect(erc721.connect(operator).permit(operatorAddress, tokenId, deadline, signature)).to.be.revertedWith(
        "InvalidSignature"
      );
    });
  });

  describe("Smart Contract Permit", async function () {
    it("can use permits to approve spender", async function () {
      await erc721.connect(minter).mint(eip1271Wallet.address, 6);
      expect(await erc721.balanceOf(eip1271Wallet.address)).to.equal(1);

      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);
      const nonce = await erc721.nonces(6);
      expect(nonce).to.be.equal(0);

      const operatorAddress = await operator.getAddress();
      const signature = await eoaSign(owner, operatorAddress, 6, nonce, deadline);

      expect(await erc721.getApproved(6)).to.not.equal(operatorAddress);

      await erc721.connect(operator).permit(operatorAddress, 6, deadline, signature);

      expect(await erc721.getApproved(6)).to.be.equal(operatorAddress);
    });

    it("does not allow approved operators to create permits on behalf of token owner", async function () {
      await erc721.connect(minter).mintByQuantity(user.address, 1);
      const deadline = Math.round(Date.now() / 1000 + 24 * 60 * 60);

      const tokenId = (await erc721.mintBatchByQuantityThreshold()).add(2);
      const nonce = await erc721.nonces(tokenId);
      expect(nonce).to.be.equal(0);

      const operatorAddress = await operator.getAddress();
      const signature = await eoaSign(owner, operatorAddress, tokenId, nonce, deadline);

      await expect(erc721.connect(operator).permit(operatorAddress, tokenId, deadline, signature)).to.be.revertedWith(
        "InvalidSignature"
      );

      expect(await erc721.getApproved(tokenId)).to.not.equal(operatorAddress);

      await operatorAllowlist.connect(registrar).addAddressToAllowlist([eip1271Wallet.address]);

      await erc721.connect(user).approve(eip1271Wallet.address, tokenId);

      await expect(erc721.connect(operator).permit(operatorAddress, tokenId, deadline, signature)).to.be.revertedWith(
        "InvalidSignature"
      );
    });
  });
});
