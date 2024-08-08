import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Crafting, MockERC721MintableBurnable } from "../../typechain-types";

const commandTypeERC721Mint = 0;
const commandTypeERC721Burn = 1;
const commandTypeERC721Transfer = 2;

describe("Crafting", () => {
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let user2: SignerWithAddress;
  let crafting: Crafting;
  let erc721: MockERC721MintableBurnable;

  beforeEach(async () => {
    // Retrieve accounts
    [owner, user, user2] = await ethers.getSigners();

    crafting = await (await ethers.getContractFactory("Crafting")).deploy();
    erc721 = await (await ethers.getContractFactory("MockERC721MintableBurnable"))
      .connect(owner)
      .deploy(owner.address, owner.address);
  });

  describe("Contract Deployment", () => {
    it("Should deploy the contract", async () => {
      expect(crafting.address).to.not.be.undefined;
    });
  });

  describe("Execute", () => {
    describe("ERC721", () => {
      it("Should burn item if approved", async () => {
        await erc721.connect(owner).safeMint(user.address, 1);
        await erc721.connect(user).approve(crafting.address, 1);
        const commands = [
          {
            token: erc721.address,
            commandType: commandTypeERC721Burn,
            data: ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [user.address, 1]),
          },
        ];
        expect(await crafting.execute(commands)).to.not.reverted;
        await expect(erc721.ownerOf(1)).to.be.reverted;
      });

      it("Should revert burn if not approved", async () => {
        await erc721.connect(owner).safeMint(user.address, 1);
        const commands = [
          {
            token: erc721.address,
            commandType: commandTypeERC721Burn,
            data: ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [user.address, 1]),
          },
        ];
        await expect(crafting.execute(commands)).to.be.revertedWith("ERC721: caller is not token owner or approved");
      });

      it("Should mint item if role is granted", async () => {
        erc721.grantRole(await erc721.MINTER_ROLE(), crafting.address);
        const commands = [
          {
            token: erc721.address,
            commandType: commandTypeERC721Mint,
            data: ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [user.address, 1]),
          },
        ];
        expect(await crafting.execute(commands)).to.not.reverted;
        expect(await erc721.ownerOf(1)).to.be.equal(user.address);
      });

      it("Should revert mint if role is not granted", async () => {
        const commands = [
          {
            token: erc721.address,
            commandType: commandTypeERC721Mint,
            data: ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [user.address, 1]),
          },
        ];
        await expect(crafting.execute(commands)).to.be.reverted;
      });

      it("Should run multiple commands", async () => {
        await erc721.connect(owner).safeMint(user.address, 1);
        await erc721.connect(user).approve(crafting.address, 1);
        await erc721.connect(owner).safeMint(user.address, 2);
        await erc721.connect(user).approve(crafting.address, 2);
        erc721.grantRole(await erc721.MINTER_ROLE(), crafting.address);
        const commands = [
          {
            token: erc721.address,
            commandType: commandTypeERC721Burn,
            data: ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [user.address, 1]),
          },
          {
            token: erc721.address,
            commandType: commandTypeERC721Transfer,
            data: ethers.utils.defaultAbiCoder.encode(
              ["address", "address", "uint256"],
              [user.address, user2.address, 2],
            ),
          },
          {
            token: erc721.address,
            commandType: commandTypeERC721Mint,
            data: ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [user.address, 3]),
          },
        ];
        expect(await crafting.execute(commands)).to.not.reverted;
        await expect(erc721.ownerOf(1)).to.be.reverted;
        expect(await erc721.ownerOf(2)).to.be.equal(user2.address);
        expect(await erc721.ownerOf(3)).to.be.equal(user.address);
      });
    });
  });
});
