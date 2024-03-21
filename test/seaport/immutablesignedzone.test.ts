/* eslint-disable camelcase */
import assert from "assert";
import { expect } from "chai";
import { Wallet, constants } from "ethers";
import { keccak256 } from "ethers/lib/utils";
import { ethers } from "hardhat";

import { ImmutableSignedZone__factory } from "../../typechain-types";

import {
  CONSIDERATION_EIP712_TYPE,
  EIP712_DOMAIN,
  SIGNED_ORDER_EIP712_TYPE,
  advanceBlockBySeconds,
  autoMining,
  convertSignatureToEIP2098,
  getCurrentTimeStamp,
} from "./utils/signedZone";

import type { ImmutableSignedZone } from "../../typechain-types";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import type { BytesLike } from "ethers";
import { ReceivedItemStruct } from "../../typechain-types/contracts/trading/seaport/ImmutableSeaport";
import { ZoneParametersStruct } from "../../typechain-types/contracts/trading/seaport/zones/ImmutableSignedZone";

describe("ImmutableSignedZone", function () {
  let deployer: SignerWithAddress;
  let users: SignerWithAddress[];
  let contract: ImmutableSignedZone;
  let chainId: number;

  beforeEach(async () => {
    // automine ensure time based tests will work
    await autoMining();
    chainId = (await ethers.provider.getNetwork()).chainId;
    users = await ethers.getSigners();
    deployer = users[0];
    const factory = await ethers.getContractFactory("ImmutableSignedZone");
    const tx = await factory.connect(deployer).deploy("ImmutableSignedZone", "", "", deployer.address);

    const address = (await tx.deployed()).address;

    contract = ImmutableSignedZone__factory.connect(address, deployer);
  });

  describe("Ownership", async function () {
    it("deployer becomes owner", async () => {
      assert((await contract.owner()) === deployer.address);
    });

    it("transferOwnership works", async () => {
      assert((await contract.owner()) === deployer.address);
      const transferTx = await contract.connect(deployer).transferOwnership(users[2].address);
      await transferTx.wait(1);

      assert((await contract.owner()) === users[2].address);
    });

    it("non owner cannot transfer ownership", async () => {
      assert((await contract.owner()) === deployer.address);
      await expect(contract.connect(users[1]).transferOwnership(users[1].address)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("non owner cannot add signer", async () => {
      await expect(contract.connect(users[1]).addSigner(users[1].address)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("non owner cannot remove signer", async () => {
      await expect(contract.connect(users[1]).removeSigner(users[1].address)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("Signer management", async () => {
    it("owner can add and remove active signer", async () => {
      assert((await contract.owner()) === deployer.address);
      const tx = await contract.connect(deployer).addSigner(users[1].address);
      await tx.wait(1);

      await expect(contract.removeSigner(users[1].address));
    });

    it("cannot add deactivated signer", async () => {
      assert((await contract.owner()) === deployer.address);
      const tx = await contract.connect(deployer).addSigner(users[1].address);
      await tx.wait(1);

      (await contract.removeSigner(users[1].address)).wait(1);

      await expect(contract.addSigner(users[1].address)).to.be.revertedWith("SignerCannotBeReauthorized");
    });

    it("already active signer cannot be added", async () => {
      assert((await contract.owner()) === deployer.address);
      const tx = await contract.connect(deployer).addSigner(users[1].address);
      await tx.wait(1);

      await expect(contract.addSigner(users[1].address)).to.be.revertedWith("SignerAlreadyActive");
    });
  });

  describe("Order Validation", async function () {
    let signer: Wallet;

    beforeEach(async () => {
      signer = ethers.Wallet.createRandom();
      // wait 1 block for all TXs
      await (await contract.addSigner(signer.address)).wait(1);
    });

    it("validateOrder reverts without extraData", async function () {
      await expect(contract.validateOrder(mockZoneParameter([]))).to.be.revertedWith("InvalidExtraData");
    });

    it("validateOrder reverts with invalid extraData", async function () {
      await expect(contract.validateOrder(mockZoneParameter([1, 2, 3]))).to.be.revertedWith("InvalidExtraData");
    });

    it("validateOrder reverts with expired timestamp", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = await getCurrentTimeStamp();
      const fulfiller = constants.AddressZero;
      const context = ethers.utils.randomBytes(32);
      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [
          0, // SIP6 version
          fulfiller,
          expiration,
          convertSignatureToEIP2098(signature),
          context,
        ]
      );

      await advanceBlockBySeconds(100);
      await expect(contract.validateOrder(mockZoneParameter(extraData))).to.be.revertedWith("SignatureExpired");
    });

    it("validateOrder reverts with invalid fulfiller", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 100;
      const fulfiller = Wallet.createRandom().address;
      const context = ethers.utils.randomBytes(32);
      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [
          0, // SIP6 version
          fulfiller,
          expiration,
          convertSignatureToEIP2098(signature),
          context,
        ]
      );

      await expect(contract.validateOrder(mockZoneParameter(extraData))).to.be.revertedWith("InvalidFulfiller");
    });

    it("validateOrder reverts with non 0 SIP6 version", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 100;
      const fulfiller = constants.AddressZero;
      const context = ethers.utils.randomBytes(32);
      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [
          1, // SIP6 version
          fulfiller,
          expiration,
          convertSignatureToEIP2098(signature),
          context,
        ]
      );

      await expect(contract.validateOrder(mockZoneParameter(extraData))).to.be.revertedWith(
        "UnsupportedExtraDataVersion"
      );
    });

    it("validateOrder reverts with no context", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 100;
      const fulfiller = constants.AddressZero;
      const context: BytesLike = [];
      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [
          0, // SIP6 version
          fulfiller,
          expiration,
          convertSignatureToEIP2098(signature),
          context,
        ]
      );

      await expect(contract.validateOrder(mockZoneParameter(extraData))).to.be.revertedWith("InvalidExtraData");
    });

    it("validateOrder reverts with wrong consideration", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 100;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const context: BytesLike = ethers.utils.solidityPack(["bytes"], [constants.HashZero]);
      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [
          0, // SIP6 version
          fulfiller,
          expiration,
          convertSignatureToEIP2098(signature),
          context,
        ]
      );

      await expect(contract.validateOrder(mockZoneParameter(extraData, consideration))).to.be.revertedWith(
        "SubstandardViolation"
      );
    });

    it("validates correct signature with context", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 100;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      const context: BytesLike = ethers.utils.solidityPack(["bytes", "bytes[]"], [considerationHash, [orderHash]]);

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      // esimate gas
      //   console.log(
      //     await contract.estimateGas.validateOrder(
      //       mockZoneParameter(extraData, consideration)
      //     )
      //   );

      expect(await contract.validateOrder(mockZoneParameter(extraData, consideration))).to.be.equal("0x17b1f942"); // ZoneInterface.validateOrder.selector
    });

    it("validateOrder reverts a valid order after expiration time passes ", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 90;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      const context: BytesLike = ethers.utils.solidityPack(["bytes", "bytes[]"], [considerationHash, [orderHash]]);

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      const selector = await contract.validateOrder(mockZoneParameter(extraData, consideration));

      expect(selector).to.equal("0x17b1f942"); // ZoneInterface.validateOrder.selector

      await advanceBlockBySeconds(900);

      expect(contract.validateOrder(mockZoneParameter(extraData, consideration))).to.be.revertedWith(
        "SignatureExpired"
      ); // ZoneInterface.validateOrder.selector
    });

    it("validateOrder validates correct context with multiple order hashes - equal arrays", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 90;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      const context: BytesLike = ethers.utils.solidityPack(
        ["bytes", "bytes[]"],
        [considerationHash, mockBulkOrderHashes()]
      );

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      // gas estimation
      //   console.log(
      //     await contract.estimateGas.validateOrder(
      //       mockZoneParameter(extraData, consideration, mockBulkOrderHashes())
      //     )
      //   );

      expect(
        await contract.validateOrder(mockZoneParameter(extraData, consideration, mockBulkOrderHashes()))
      ).to.be.equal("0x17b1f942"); // ZoneInterface.validateOrder.selector
    });

    it("validateOrder validates correct context with multiple order hashes - partial arrays", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 90;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      const context: BytesLike = ethers.utils.solidityPack(
        ["bytes", "bytes[]"],
        [considerationHash, mockBulkOrderHashes().splice(0, 2)]
      );

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      expect(
        await contract.validateOrder(mockZoneParameter(extraData, consideration, mockBulkOrderHashes()))
      ).to.be.equal("0x17b1f942"); // ZoneInterface.validateOrder.selector
    });

    it("validateOrder reverts when not all expected order hashes are in zone parameters", async function () {
      // this triggers the early break in contract's array helper
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 90;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      // context with 10 order hashes expected
      const context: BytesLike = ethers.utils.solidityPack(
        ["bytes", "bytes[]"],
        [considerationHash, mockBulkOrderHashes()]
      );

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      await expect(
        contract.validateOrder(
          // only 8 order hashes actually filled
          mockZoneParameter(extraData, consideration, mockBulkOrderHashes().splice(0, 2))
        )
      ).to.be.revertedWith("SubstandardViolation");
    });

    it("validateOrder reverts when not all expected order hashes are in zone parameters variation", async function () {
      // this doesn't trigger the early break in contract's array helper
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 90;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      // context with 10 order hashes expected
      const context: BytesLike = ethers.utils.solidityPack(
        ["bytes", "bytes[]"],
        [considerationHash, mockBulkOrderHashes()]
      );

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      const signature = await signer._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      // remove two and add two random order hashes
      const mockActualOrderHashes = mockBulkOrderHashes().splice(0, 2);
      mockActualOrderHashes.push(keccak256("0x55"), keccak256("0x66"));

      await expect(
        contract.validateOrder(
          // only 8 order hashes actually filled
          mockZoneParameter(extraData, consideration, mockActualOrderHashes)
        )
      ).to.be.revertedWith("SubstandardViolation");
    });

    it("validateOrder reverts incorrectly signed signature with context", async function () {
      const orderHash = keccak256("0x1234");
      const expiration = (await getCurrentTimeStamp()) + 100;
      const fulfiller = constants.AddressZero;
      const consideration = mockConsideration();
      const considerationHash = ethers.utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
        consideration,
      });

      const context: BytesLike = ethers.utils.solidityPack(["bytes"], [considerationHash]);

      const signedOrder = {
        fulfiller,
        expiration,
        orderHash,
        context,
      };

      // sign with random user
      const signature = await users[4]._signTypedData(
        EIP712_DOMAIN(chainId, contract.address),
        SIGNED_ORDER_EIP712_TYPE,
        signedOrder
      );

      const extraData = ethers.utils.solidityPack(
        ["bytes1", "address", "uint64", "bytes", "bytes"],
        [0, fulfiller, expiration, convertSignatureToEIP2098(signature), context]
      );

      expect(contract.validateOrder(mockZoneParameter(extraData, consideration))).to.be.revertedWith("SignerNotActive");
    });
  });
});

function mockConsideration(howMany: number = 10): ReceivedItemStruct[] {
  const consideration: ReceivedItemStruct[] = [];
  for (let i = 0; i < howMany; i++) {
    consideration.push({
      itemType: 0,
      token: Wallet.createRandom().address,
      identifier: 123,
      amount: 12,
      recipient: Wallet.createRandom().address,
    });
  }

  return consideration;
}

function mockBulkOrderHashes(howMany: number = 10): string[] {
  const hashes: string[] = [];
  for (let i = 0; i < howMany; i++) {
    hashes.push(keccak256(`0x123${i >= 10 ? i + "0" : i}`));
  }
  return hashes;
}

function mockZoneParameter(
  extraData: BytesLike,
  consideration: ReceivedItemStruct[] = [],
  orderHashes: string[] = [keccak256("0x1234")]
): ZoneParametersStruct {
  return {
    // fix order hash for testing (zone doesn't validate its actual validity)
    orderHash: keccak256("0x1234"),
    fulfiller: constants.AddressZero,
    // zero address - also does not get validated in zone
    offerer: constants.AddressZero,
    // empty offer - no validation in zone
    offer: [],
    consideration,
    extraData,
    orderHashes,
    startTime: 0,
    endTime: 0,
    // we do not use zone hash
    zoneHash: constants.HashZero,
  };
}
