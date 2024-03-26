/* eslint-disable no-unused-expressions */
import { ethers, network } from "hardhat";
import { randomBytes } from "crypto";

import type { ImmutableSeaport, ImmutableSignedZone, TestERC721 } from "../../../typechain-types";
import { constants } from "ethers";
import type { Wallet, BigNumber, BigNumberish } from "ethers";
import { deployImmutableContracts } from "./utils/deploy-immutable-contracts";
import { faucet } from "./utils/faucet";
import { buildResolver, getItemETH, toBN, toKey } from "./utils/encoding";
import { deployERC721, getTestItem721, getTestItem721WithCriteria, mintAndApprove721 } from "./utils/erc721";
import { createOrder, generateSip7Signature } from "./utils/order";
import { expect } from "chai";
import { merkleTree } from "./utils/criteria";

const { parseEther } = ethers.utils;

describe(`ImmutableSeaport and ImmutableZone (Seaport v1.5)`, function () {
  const { provider } = ethers;
  const owner = new ethers.Wallet(randomBytes(32), provider);
  const immutableSigner = new ethers.Wallet(randomBytes(32), provider);

  let immutableSignedZone: ImmutableSignedZone;
  let immutableSeaport: ImmutableSeaport;
  let conduitKey: string;
  let conduitAddress: string;

  function getEthBalance(userAddress: string): Promise<BigNumber> {
    return provider.getBalance(userAddress);
  }

  async function userIsOwnerOfNft(erc721: TestERC721, tokenId: BigNumberish, userAddress: string): Promise<boolean> {
    const ownerOf = await erc721.ownerOf(tokenId);
    return ownerOf === userAddress;
  }

  after(async () => {
    await network.provider.request({
      method: "hardhat_reset",
    });
  });

  before(async () => {
    await faucet(owner.address, provider);
    const immutableContracts = await deployImmutableContracts(immutableSigner.address);
    immutableSeaport = immutableContracts.immutableSeaport;
    immutableSignedZone = immutableContracts.immutableSignedZone;
    conduitKey = immutableContracts.conduitKey;
    conduitAddress = immutableContracts.conduitAddress;
  });

  let buyer: Wallet;
  let seller: Wallet;

  beforeEach(async () => {
    buyer = new ethers.Wallet(randomBytes(32), provider);
    seller = new ethers.Wallet(randomBytes(32), provider);
    await faucet(buyer.address, provider);
    await faucet(seller.address, provider);
  });

  describe("Events", () => {
    it("Emits AllowedZoneSet event", async () => {
      const zone = new ethers.Wallet(randomBytes(32)).address;
      const allowed = true;
      expect(
        await immutableSeaport
          .connect((await ethers.getSigners())[0]) // use default deployer (admin)
          .setAllowedZone(zone, allowed)
      )
        .to.emit(immutableSeaport, "AllowedZoneSet")
        .withArgs(zone, allowed);
    });
  });

  describe("Order fulfillment", () => {
    it("ImmutableSeaport can fulfill an Immutable-signed FULL_RESTRICTED advanced order", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, conduitAddress);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        [offer],
        consideration,
        2, // FULL_RESTRICTED
        undefined,
        undefined,
        undefined,
        conduitKey
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      const sellerBalanceBefore = await getEthBalance(seller.address);
      const buyerBalanceBefore = await getEthBalance(seller.address);

      const tx = await immutableSeaport.connect(buyer).fulfillAdvancedOrder(order, [], conduitKey, buyer.address, {
        value,
      });

      await tx.wait();

      expect(await userIsOwnerOfNft(erc721, nftId, buyer.address)).to.be.true;
      expect(await userIsOwnerOfNft(erc721, nftId, seller.address)).to.be.false;
      expect(await getEthBalance(seller.address)).to.equal(sellerBalanceBefore.add(parseEther("10")));

      const currentBalance = await getEthBalance(buyer.address);
      const expectedBalance = buyerBalanceBefore.sub(parseEther("10"));

      // Balance is less than 10 because of gas fees
      // Chai doesn't seem to like ethers.BigNumber comparisons
      expect(currentBalance.lt(expectedBalance)).to.be.true;
    });

    it("ImmutableSeaport can fulfill an Immutable-signed PARTIAL_RESTRICTED advanced order", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        [offer],
        consideration,
        3 // PARTIAL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      const sellerBalanceBefore = await getEthBalance(seller.address);
      const buyerBalanceBefore = await getEthBalance(seller.address);

      const tx = await immutableSeaport.connect(buyer).fulfillAdvancedOrder(order, [], toKey(0), buyer.address, {
        value,
      });

      await tx.wait();

      expect(await userIsOwnerOfNft(erc721, nftId, buyer.address)).to.be.true;
      expect(await userIsOwnerOfNft(erc721, nftId, seller.address)).to.be.false;
      expect(await getEthBalance(seller.address)).to.equal(sellerBalanceBefore.add(parseEther("10")));
      // Balance is less than 10 because of gas fees
      expect((await getEthBalance(buyer.address)).lt(buyerBalanceBefore.sub(parseEther("10")))).to.be.true;
    });

    it("ImmutableSeaport rejects unsupported zones", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        // Random address for zone
        new ethers.Wallet(randomBytes(32)).address,
        [offer],
        consideration,
        2 // FULL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      await expect(
        immutableSeaport
          .connect(buyer)
          .fulfillAdvancedOrder(order, [], toKey(0), ethers.constants.AddressZero, {
            value,
          })
          .then((tx) => tx.wait())
      ).to.be.revertedWith("InvalidZone");
    });

    it("ImmutableSeaport rejects an Immutable-signed FULL_OPEN advanced order", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        [offer],
        consideration,
        0 // FULL_OPEN
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      await expect(
        immutableSeaport
          .connect(buyer)
          .fulfillAdvancedOrder(order, [], toKey(0), ethers.constants.AddressZero, {
            value,
          })
          .then((tx) => tx.wait())
      ).to.be.revertedWith("OrderNotRestricted");
    });

    it("ImmutableSeaport can fulfill an Immutable-signed FULL_RESTRICTED advanced order with criteria", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);

      const { root, proofs } = merkleTree([nftId]);

      const offer = [getTestItem721WithCriteria(erc721.address, root, toBN(1), toBN(1))];
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const criteriaResolvers = [buildResolver(0, 0, 0, nftId, proofs[nftId.toString()])];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        offer,
        consideration,
        2 // FULL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      const sellerBalanceBefore = await getEthBalance(seller.address);
      const buyerBalanceBefore = await getEthBalance(seller.address);

      const tx = await immutableSeaport
        .connect(buyer)
        .fulfillAdvancedOrder(order, criteriaResolvers, toKey(0), buyer.address, {
          value,
        });

      await tx.wait();

      expect(await userIsOwnerOfNft(erc721, nftId, buyer.address)).to.be.true;
      expect(await userIsOwnerOfNft(erc721, nftId, seller.address)).to.be.false;
      expect(await getEthBalance(seller.address)).to.equal(sellerBalanceBefore.add(parseEther("10")));
      // Balance is less than 10 because of gas fees
      expect((await getEthBalance(buyer.address)).lt(buyerBalanceBefore.sub(parseEther("10")))).to.be.true;
    });

    it("ImmutableSeaport can fulfill an Immutable-signed PARTIAL_RESTRICTED advanced order", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        [offer],
        consideration,
        3 // PARTIAL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      const sellerBalanceBefore = await getEthBalance(seller.address);
      const buyerBalanceBefore = await getEthBalance(seller.address);

      const tx = await immutableSeaport.connect(buyer).fulfillAdvancedOrder(order, [], toKey(0), buyer.address, {
        value,
      });

      await tx.wait();

      expect(await userIsOwnerOfNft(erc721, nftId, buyer.address)).to.be.true;
      expect(await userIsOwnerOfNft(erc721, nftId, seller.address)).to.be.false;
      expect(await getEthBalance(seller.address)).to.equal(sellerBalanceBefore.add(parseEther("10")));
      // Balance is less than 10 because of gas fees
      expect((await getEthBalance(buyer.address)).lt(buyerBalanceBefore.sub(parseEther("10")))).to.be.true;
    });

    it("Orders submitted against a zone that has been disabled are rejected", async () => {
      const contracts = await deployImmutableContracts(immutableSigner.address);
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, contracts.immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];

      // Disable the zone
      await contracts.immutableSeaport.setAllowedZone(contracts.immutableSignedZone.address, false);

      const { order, orderHash, value } = await createOrder(
        contracts.immutableSeaport,
        seller,
        contracts.immutableSignedZone,
        [offer],
        consideration,
        3 // PARTIAL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      await expect(
        immutableSeaport
          .connect(buyer)
          .fulfillAdvancedOrder(order, [], toKey(0), ethers.constants.AddressZero, {
            value,
          })
          .then((tx) => tx.wait())
      ).to.be.revertedWith("InvalidZone");
    });

    it("Orders with extraData signed by the wrong signer are rejected", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, orderHash, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        [offer],
        consideration,
        3 // PARTIAL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        orderHash,
        buyer.address,
        immutableSignedZone.address,
        // Random signer
        new ethers.Wallet(randomBytes(32), provider)
      );

      order.extraData = extraData;

      await expect(
        immutableSeaport
          .connect(buyer)
          .fulfillAdvancedOrder(order, [], toKey(0), ethers.constants.AddressZero, {
            value,
          })
          .then((tx) => tx.wait())
      ).to.be.revertedWith("SignerNotActive");
    });

    it("Orders with invalid extraData are rejected", async () => {
      const erc721 = await deployERC721();
      const nftId = await mintAndApprove721(erc721, seller, immutableSeaport.address);
      const offer = await getTestItem721(erc721.address, nftId);
      const consideration = [getItemETH(parseEther("10"), parseEther("10"), seller.address)];
      const { order, value } = await createOrder(
        immutableSeaport,
        seller,
        immutableSignedZone,
        [offer],
        consideration,
        3 // PARTIAL_RESTRICTED
      );

      const extraData = await generateSip7Signature(
        consideration,
        // Bad order hash
        constants.HashZero,
        buyer.address,
        immutableSignedZone.address,
        immutableSigner
      );

      // sign the orderHash with immutableSigner
      order.extraData = extraData;

      await expect(
        immutableSeaport
          .connect(buyer)
          .fulfillAdvancedOrder(order, [], toKey(0), ethers.constants.AddressZero, {
            value,
          })
          .then((tx) => tx.wait())
      ).to.be.revertedWith("SubstandardViolation");
    });
  });
});
