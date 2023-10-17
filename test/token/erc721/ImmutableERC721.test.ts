import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ImmutableERC721, OperatorAllowlist } from "../../../typechain-types";
import { AllowlistFixture } from "../../utils/DeployHybridFixtures";

describe("ImmutableERC721", function () {
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

  describe("Contract Deployment", function () {
    it("Should set the admin role to the owner", async function () {
      const adminRole = await erc721.DEFAULT_ADMIN_ROLE();
      expect(await erc721.hasRole(adminRole, owner.address)).to.be.equal(true);
    });

    it("Should set the name and symbol of the collection", async function () {
      expect(await erc721.name()).to.equal(name);
      expect(await erc721.symbol()).to.equal(symbol);
    });

    it("Should set collection URI", async function () {
      expect(await erc721.contractURI()).to.equal(contractURI);
    });

    it("Should set base URI", async function () {
      expect(await erc721.baseURI()).to.equal(baseURI);
    });
  });

  describe("Minting access control", function () {
    it("Should return the addresses which have DEFAULT_ADMIN_ROLE", async function () {
      const admins = await erc721.getAdmins();
      expect(admins[0]).to.equal(owner.address);
    });

    it("Should allow an admin to grant and revoke MINTER_ROLE", async function () {
      const minterRole = await erc721.MINTER_ROLE();

      // Grant
      await erc721.connect(owner).grantMinterRole(user.address);
      let hasRole = await erc721.hasRole(minterRole, user.address);
      expect(hasRole).to.equal(true);

      // Revoke
      await erc721.connect(owner).revokeMinterRole(user.address);
      hasRole = await erc721.hasRole(minterRole, user.address);
      expect(hasRole).to.equal(false);
    });
  });

  describe("Minting and burning", function () {
    it("Should allow a member of the minter role to mint", async function () {
      await erc721.connect(minter).mint(user.address, 1);
      expect(await erc721.balanceOf(user.address)).to.equal(1);
      expect(await erc721.totalSupply()).to.equal(1);
    });

    it("Should allow a member of the minter role to safe mint", async function () {
      await erc721.connect(minter).safeMint(user.address, 2);
      expect(await erc721.balanceOf(user.address)).to.equal(2);
      expect(await erc721.totalSupply()).to.equal(2);
    });

    it("Should revert when caller does not have minter role", async function () {
      await expect(erc721.connect(user).mint(user.address, 3)).to.be.revertedWith(
        "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x4d494e5445525f524f4c45000000000000000000000000000000000000000000"
      );
    });

    it("Should allow minting of batch tokens", async function () {
      const mintRequests = [
        { to: user.address, tokenIds: [3, 4, 5] },
        { to: owner.address, tokenIds: [6, 7, 8] },
      ];
      await erc721.connect(minter).mintBatch(mintRequests);
      expect(await erc721.balanceOf(user.address)).to.equal(5);
      expect(await erc721.balanceOf(owner.address)).to.equal(3);
      expect(await erc721.totalSupply()).to.equal(8);
      expect(await erc721.ownerOf(3)).to.equal(user.address);
      expect(await erc721.ownerOf(4)).to.equal(user.address);
      expect(await erc721.ownerOf(5)).to.equal(user.address);
      expect(await erc721.ownerOf(6)).to.equal(owner.address);
      expect(await erc721.ownerOf(7)).to.equal(owner.address);
      expect(await erc721.ownerOf(8)).to.equal(owner.address);
    });

    it("Should allow minting of batch tokens", async function () {
      const mintRequests = [
        { to: user.address, tokenIds: [9, 10, 11, 20] },
        { to: owner.address, tokenIds: [12, 13, 14] },
      ];
      await erc721.connect(minter).safeMintBatch(mintRequests);
      expect(await erc721.balanceOf(user.address)).to.equal(9);
      expect(await erc721.balanceOf(owner.address)).to.equal(6);
      expect(await erc721.totalSupply()).to.equal(15);
      expect(await erc721.ownerOf(9)).to.equal(user.address);
      expect(await erc721.ownerOf(10)).to.equal(user.address);
      expect(await erc721.ownerOf(11)).to.equal(user.address);
      expect(await erc721.ownerOf(12)).to.equal(owner.address);
      expect(await erc721.ownerOf(13)).to.equal(owner.address);
      expect(await erc721.ownerOf(14)).to.equal(owner.address);
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

    it("Should allow owner or approved to burn a batch of tokens", async function () {
      const originalBalance = await erc721.balanceOf(user.address);
      const originalSupply = await erc721.totalSupply();
      const batch = [1, 2];
      await erc721.connect(user).burnBatch(batch);
      expect(await erc721.balanceOf(user.address)).to.equal(originalBalance.sub(batch.length));
      expect(await erc721.totalSupply()).to.equal(originalSupply.sub(batch.length));
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

    it("Should return an empty token URI when the base URI is not set", async function () {
      await erc721.setBaseURI("");
      const tokenId = 16;
      await erc721.connect(minter).mint(user.address, tokenId);
      expect(await erc721.tokenURI(tokenId)).to.equal("");
    });
  });

  describe("Contract URI", function () {
    it("Should allow the default admin to update the contract URI", async function () {
      const newContractURI = "New Contract URI";
      await erc721.connect(owner).setContractURI(newContractURI);
      expect(await erc721.contractURI()).to.equal(newContractURI);
    });

    it("Should revert with a caller does not have admin role", async function () {
      await expect(erc721.connect(user).setContractURI("New Contract URI")).to.be.revertedWith(
        "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });

  describe("Supported Interfaces", function () {
    it("Should return true on supported interfaces", async function () {
      // ERC165
      expect(await erc721.supportsInterface("0x01ffc9a7")).to.equal(true);
      // ERC721
      expect(await erc721.supportsInterface("0x80ac58cd")).to.equal(true);
      // ERC721Metadata
      expect(await erc721.supportsInterface("0x5b5e139f")).to.equal(true);
    });
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

  describe("Royalties", function () {
    it("Should set the correct royalties", async function () {
      const salePrice = ethers.utils.parseEther("1");
      const tokenInfo = await erc721.royaltyInfo(2, salePrice);

      expect(tokenInfo[0]).to.be.equal(owner.address);
      // (_salePrice * royalty.royaltyFraction) / _feeDenominator();
      // (1e18 * 2000) / 10000 = 2e17 (0.2 eth)
      expect(tokenInfo[1]).to.be.equal(ethers.utils.parseEther("0.02"));
    });
  });

  describe("Transfers", function () {
    it("Should revert when TransferRequest contains mismatched array lengths", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();

      const transferRequest = {
        from: minter.address,
        tos: [user.address, user.address, user2.address, user2.address, user2.address],
        tokenIds: [51, 52, 53, first.add(11).toString()],
      };

      await expect(
        erc721.connect(ethers.provider.getSigner(transferRequest.from)).safeTransferFromBatch(transferRequest)
      ).to.be.revertedWith("IImmutableERC721MismatchedTransferLengths");
    });

    it("Should allow users to transfer tokens using safeTransferFromBatch", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      // Mint tokens for testing transfers
      const mintRequests = [
        { to: minter.address, tokenIds: [51, 52, 53] },
        { to: user.address, tokenIds: [54, 55, 56] },
        { to: user2.address, tokenIds: [57, 58, 59] },
      ];

      await erc721.connect(minter).mintBatch(mintRequests);
      await erc721.connect(minter).mintByQuantity(minter.address, 2);

      // Define transfer requests
      const transferRequests = [
        {
          from: minter.address,
          tos: [user.address, user.address, user2.address, user2.address, user2.address],
          tokenIds: [51, 52, 53, first.add(16).toString(), first.add(15).toString()],
        },
        {
          from: user.address,
          tos: [minter.address, minter.address],
          tokenIds: [54, 55],
        },
        { from: user2.address, tos: [minter.address], tokenIds: [57] },
      ];

      // Verify ownership before transfer
      expect(await erc721.ownerOf(51)).to.equal(minter.address);
      expect(await erc721.ownerOf(54)).to.equal(user.address);
      expect(await erc721.ownerOf(57)).to.equal(user2.address);

      expect(await erc721.ownerOf(first.add(16).toString())).to.equal(minter.address);
      expect(await erc721.ownerOf(first.add(15).toString())).to.equal(minter.address);

      // Perform transfers
      for (const transferReq of transferRequests) {
        await erc721.connect(ethers.provider.getSigner(transferReq.from)).safeTransferFromBatch(transferReq);
      }

      // Verify ownership after transfer
      expect(await erc721.ownerOf(51)).to.equal(user.address);
      expect(await erc721.ownerOf(52)).to.equal(user.address);
      expect(await erc721.ownerOf(53)).to.equal(user2.address);
      expect(await erc721.ownerOf(54)).to.equal(minter.address);
      expect(await erc721.ownerOf(55)).to.equal(minter.address);
      expect(await erc721.ownerOf(57)).to.equal(minter.address);
      expect(await erc721.ownerOf(first.add(16).toString())).to.equal(user2.address);
      expect(await erc721.ownerOf(first.add(15).toString())).to.equal(user2.address);
    });
  });
});
