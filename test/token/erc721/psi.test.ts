import { ImmutableERC721, RoyaltyAllowlist } from "../../../typechain";
import { AllowlistFixture } from "../../utils/DeployFixtures";

const { expect } = require('chai');
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
const { constants } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const RECEIVER_MAGIC_VALUE = '0x150b7a02';
const GAS_MAGIC_VALUE = 20000;

describe.only('ERC721Psi', function () {

    let erc721: ImmutableERC721;
    let royaltyAllowlist: RoyaltyAllowlist;
    let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let user2: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let royaltyRecipient: SignerWithAddress;

  beforeEach(async function () {

    [owner, user, minter, registrar, royaltyRecipient, user2] =
      await ethers.getSigners();

    ({ erc721, royaltyAllowlist } = await AllowlistFixture(owner));

    await erc721.connect(owner).grantMinterRole(minter.address);
    await royaltyAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });

  context('with no minted tokens', async function () {
    it('has 0 totalSupply', async function () {
      const supply = await erc721.totalSupply();
      expect(supply).to.equal(0);
    });
  });

  context('with minted tokens', async function () {
    beforeEach(async function () {
      const [owner, addr1, addr2, addr3] = await ethers.getSigners();
      this.owner = owner;
      this.addr1 = addr1;
      this.addr2 = addr2;
      this.addr3 = addr3;
      await erc721.connect(minter).mintByQuantity(addr1.address, 1);
      await erc721.connect(minter).mintByQuantity(addr2.address, 2);
      await erc721.connect(minter).mintByQuantity(addr3.address, 3);
    });

    it('has 6 totalSupply', async function () {
      const supply = await erc721.totalSupply();
      expect(supply).to.equal(6);
    });

    describe('exists', async function () {
      it('verifies valid tokens', async function () {
        const first = await erc721.bulkMintThreshold();
        for (let i = 0; i < 6; i++) {
          const exists = await erc721.exists(first.add(i));
          expect(exists).to.be.true;
        }
      });

      it('verifies invalid tokens', async function () {
        const first = await erc721.bulkMintThreshold();
        const exists = await erc721.exists(first.add(6));
        expect(exists).to.be.false;
      });
    });

    describe('balanceOf', async function () {
      it('returns the amount for a given address', async function () {
        expect(await erc721.balanceOf(this.owner.address)).to.equal('0');
        expect(await erc721.balanceOf(this.addr1.address)).to.equal('1');
        expect(await erc721.balanceOf(this.addr2.address)).to.equal('2');
        expect(await erc721.balanceOf(this.addr3.address)).to.equal('3');
      });

      it('throws an exception for the 0 address', async function () {
        await expect(erc721.balanceOf(ZERO_ADDRESS)).to.be.reverted;
      });
    });

    describe('ownerOf', async function () {
      it('returns the right owner', async function () {
        const first = await erc721.bulkMintThreshold();
        expect(await erc721.ownerOf(first)).to.equal(this.addr1.address);
        expect(await erc721.ownerOf(first.add(1))).to.equal(this.addr2.address);
        expect(await erc721.ownerOf(first.add(5))).to.equal(this.addr3.address);
      });

      it('reverts for an invalid token', async function () {
        const first = await erc721.bulkMintThreshold();
        await expect(erc721.ownerOf(first.add(10))).to.be.reverted;
      });
    });

    describe('tokensOfOwner', async function () {
      it('returns the right owner list', async function () {
        const first = await erc721.bulkMintThreshold();
        expect(await erc721.tokensOfOwner(this.addr1.address)).to.eqls([first]);
        expect(await erc721.tokensOfOwner(this.addr2.address)).to.eqls([first.add(1), first.add(2)]);
        expect(await erc721.tokensOfOwner(this.addr3.address)).to.eqls([first.add(3), first.add(4), first.add(5)]);
      });
    });

    describe('approve', async function () {
        const first = await erc721.bulkMintThreshold();
      const tokenId = first;
      const tokenId2 = first.add(1);

      it('sets approval for the target address', async function () {
        await erc721.connect(this.addr1).approve(this.addr2.address, tokenId);
        const approval = await erc721.getApproved(tokenId);
        expect(approval).to.equal(this.addr2.address);
      });

      it('rejects an invalid token owner', async function () {
        await expect(erc721.connect(this.addr1).approve(this.addr2.address, tokenId2)).to.be.reverted;
      });

      it('rejects an unapproved caller', async function () {
        await expect(erc721.approve(this.addr2.address, tokenId)).to.revert();
      });

      it('does not get approved for invalid tokens', async function () {
        await expect(erc721.getApproved(10)).to.be.reverted;
      });
    });

    describe('setApprovalForAll', async function () {
      it('sets approval for all properly', async function () {
        const approvalTx = await erc721.setApprovalForAll(this.addr1.address, true);
        await expect(approvalTx)
          .to.emit(erc721, 'ApprovalForAll')
          .withArgs(this.owner.address, this.addr1.address, true);
        expect(await erc721.isApprovedForAll(this.owner.address, this.addr1.address)).to.be.true;
      });

      it('sets rejects approvals for non msg senders', async function () {
        await expect(erc721.connect(this.addr1).setApprovalForAll(this.addr1.address, true)).to.be.reverted;
      });
    });

    context('test transfer functionality', function () {
      const testSuccessfulTransfer = async function () {
        const first = await erc721.bulkMintThreshold();
        const tokenId = first;
        let from: string;
        let to: string;

        beforeEach(async function () {
          const sender = user;
          from = sender.address;
          to = owner.address;
          await erc721.connect(sender).setApprovalForAll(to, true);
          this.transferTx = await erc721.connect(sender).transferFrom(from, to, tokenId);
        });

        it('transfers the ownership of the given token ID to the given address', async function () {
          expect(await erc721.ownerOf(tokenId)).to.be.equal(to);
        });

        it('emits a Transfer event', async function () {
          await expect(this.transferTx).to.emit(erc721, 'Transfer').withArgs(from, to, tokenId);
        });

        it('clears the approval for the token ID', async function () {
          expect(await erc721.getApproved(tokenId)).to.be.equal(ZERO_ADDRESS);
        });

        it('emits an Approval event', async function () {
          await expect(this.transferTx).to.emit(erc721, 'Approval').withArgs(from, ZERO_ADDRESS, tokenId);
        });

        it('adjusts owners balances', async function () {
          expect(await erc721.balanceOf(from)).to.be.equal(1);
        });

      };

      const testUnsuccessfulTransfer = () => {
        const tokenId = 1;

        it('rejects unapproved transfer', async function () {
          await expect(
            erc721.connect(this.addr1).transferFrom(this.addr2.address, this.addr1.address, tokenId)
          ).to.be.reverted;
        });

        it('rejects transfer from incorrect owner', async function () {
          await erc721.connect(this.addr2).setApprovalForAll(this.addr1.address, true);
          await expect(
            erc721.connect(this.addr1).transferFrom(this.addr3.address, this.addr1.address, tokenId)
          ).to.be.reverted;
        });

        it('rejects transfer to zero address', async function () {
          await erc721.connect(this.addr2).setApprovalForAll(this.addr1.address, true);
          await expect(
            erc721.connect(this.addr1).transferFrom(this.addr2.address, ZERO_ADDRESS, tokenId)
          ).to.be.reverted;
        });
      };

      context('successful transfers', function () {
        describe('transferFrom', function () {
          testSuccessfulTransfer();
        });

        // describe('safeTransferFrom', function () {
        //   testSuccessfulTransfer();

        //   it('validates ERC721Received', async function () {
        //     await expect(this.transferTx)
        //       .to.emit(this.receiver, 'Received')
        //       .withArgs(this.addr2.address, this.addr2.address, 1, '0x', GAS_MAGIC_VALUE);
        //   });
        // });
      });

      context('unsuccessful transfers', function () {
        describe('transferFrom', function () {
          testUnsuccessfulTransfer();
        });

        // describe('safeTransferFrom', function () {
        //   testUnsuccessfulTransfer('safeTransferFrom(address,address,uint256)');
        // });
      });
    });
  });

//   context('mint', async function () {
//     beforeEach(async function () {
//       const [owner, addr1, addr2] = await ethers.getSigners();
//       this.owner = owner;
//       this.addr1 = addr1;
//       this.addr2 = addr2;
//       this.receiver = await this.ERC721Receiver.deploy(RECEIVER_MAGIC_VALUE);
//     });

//     describe('safeMint', function () {
//       it('successfully mints a single token', async function () {
//         const mintTx = await erc721.safeMintByQuantity(this.receiver.address, 1);
//         await expect(mintTx).to.emit(erc721, 'Transfer').withArgs(ZERO_ADDRESS, this.receiver.address, 0);
//         await expect(mintTx)
//           .to.emit(this.receiver, 'Received')
//           .withArgs(this.owner.address, ZERO_ADDRESS, 0, '0x', GAS_MAGIC_VALUE);
//         expect(await erc721.ownerOf(0)).to.equal(this.receiver.address);
//       });

//       it('successfully mints multiple tokens', async function () {
//         const mintTx = await erc721.safeMintByQuantity(this.receiver.address, 5);
//         for (let tokenId = 0; tokenId < 5; tokenId++) {
//           await expect(mintTx).to.emit(erc721, 'Transfer').withArgs(ZERO_ADDRESS, this.receiver.address, tokenId);
//           await expect(mintTx)
//             .to.emit(this.receiver, 'Received')
//             .withArgs(this.owner.address, ZERO_ADDRESS, 0, '0x', GAS_MAGIC_VALUE);
//           expect(await erc721.ownerOf(tokenId)).to.equal(this.receiver.address);
//         }
//       });

//       it('rejects mints to the zero address', async function () {
//         await expect(erc721.safeMintByQuantity(ZERO_ADDRESS, 1)).to.be.revertedWith(
//           'ERC721Psi: mint to the zero address'
//         );
//       });

//       it('requires quantity to be greater 0', async function () {
//         await expect(erc721.safeMintByQuantity(this.owner.address, 0)).to.be.revertedWith(
//           'ERC721Psi: quantity must be greater 0'
//         );
//       });
//     });
//   });
});