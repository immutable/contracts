import { randomBytes } from "crypto";
import { BigNumber, constants, utils } from "ethers";
import type { BigNumberish } from "ethers";
import { ConsiderationItem, CriteriaResolver, OfferItem, OrderComponents } from "./types";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { expect } from "chai";

export const randomHex = (bytes = 32) => `0x${randomBytes(bytes).toString("hex")}`;
export const toBN = (n: BigNumberish) => BigNumber.from(toHex(n));
export const randomBN = (bytes: number = 16) => toBN(randomHex(bytes));
export const toKey = (n: BigNumberish) => toHex(n, 32);
export const toHex = (n: BigNumberish, numBytes: number = 0) => {
  const asHexString = BigNumber.isBigNumber(n)
    ? n.toHexString().slice(2)
    : typeof n === "string"
    ? hexRegex.test(n)
      ? n.replace(/0x/, "")
      : Number(n).toString(16)
    : Number(n).toString(16);
  return `0x${asHexString.padStart(numBytes * 2, "0")}`;
};

const hexRegex = /[A-Fa-fx]/g;

export const getItemETH = (startAmount: BigNumberish = 1, endAmount: BigNumberish = 1, recipient?: string) =>
  getOfferOrConsiderationItem(0, constants.AddressZero, 0, toBN(startAmount), toBN(endAmount), recipient);

export const getItem721 = (
  token: string,
  identifierOrCriteria: BigNumberish,
  startAmount: number = 1,
  endAmount: number = 1,
  recipient?: string
) => getOfferOrConsiderationItem(2, token, identifierOrCriteria, startAmount, endAmount, recipient);

export const getOfferOrConsiderationItem = <RecipientType extends string | undefined = undefined>(
  itemType: number = 0,
  token: string = constants.AddressZero,
  identifierOrCriteria: BigNumberish = 0,
  startAmount: BigNumberish = 1,
  endAmount: BigNumberish = 1,
  recipient?: RecipientType
): RecipientType extends string ? ConsiderationItem : OfferItem => {
  const offerItem: OfferItem = {
    itemType,
    token,
    identifierOrCriteria: toBN(identifierOrCriteria),
    startAmount: toBN(startAmount),
    endAmount: toBN(endAmount),
  };
  if (typeof recipient === "string") {
    return {
      ...offerItem,
      recipient: recipient as string,
    } as ConsiderationItem;
  }
  return offerItem as any;
};

export const convertSignatureToEIP2098 = (signature: string) => {
  if (signature.length === 130) {
    return signature;
  }

  expect(signature.length, "signature must be 64 or 65 bytes").to.eq(132);

  return utils.splitSignature(signature).compact;
};

export const calculateOrderHash = (orderComponents: OrderComponents) => {
  const offerItemTypeString =
    "OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)";
  const considerationItemTypeString =
    "ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)";
  const orderComponentsPartialTypeString =
    "OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)";
  const orderTypeString = `${orderComponentsPartialTypeString}${considerationItemTypeString}${offerItemTypeString}`;

  const offerItemTypeHash = keccak256(toUtf8Bytes(offerItemTypeString));
  const considerationItemTypeHash = keccak256(toUtf8Bytes(considerationItemTypeString));
  const orderTypeHash = keccak256(toUtf8Bytes(orderTypeString));

  const offerHash = keccak256(
    "0x" +
      orderComponents.offer
        .map((offerItem) => {
          return keccak256(
            "0x" +
              [
                offerItemTypeHash.slice(2),
                offerItem.itemType.toString().padStart(64, "0"),
                offerItem.token.slice(2).padStart(64, "0"),
                toBN(offerItem.identifierOrCriteria).toHexString().slice(2).padStart(64, "0"),
                toBN(offerItem.startAmount).toHexString().slice(2).padStart(64, "0"),
                toBN(offerItem.endAmount).toHexString().slice(2).padStart(64, "0"),
              ].join("")
          ).slice(2);
        })
        .join("")
  );

  const considerationHash = keccak256(
    "0x" +
      orderComponents.consideration
        .map((considerationItem) => {
          return keccak256(
            "0x" +
              [
                considerationItemTypeHash.slice(2),
                considerationItem.itemType.toString().padStart(64, "0"),
                considerationItem.token.slice(2).padStart(64, "0"),
                toBN(considerationItem.identifierOrCriteria).toHexString().slice(2).padStart(64, "0"),
                toBN(considerationItem.startAmount).toHexString().slice(2).padStart(64, "0"),
                toBN(considerationItem.endAmount).toHexString().slice(2).padStart(64, "0"),
                considerationItem.recipient.slice(2).padStart(64, "0"),
              ].join("")
          ).slice(2);
        })
        .join("")
  );

  const derivedOrderHash = keccak256(
    "0x" +
      [
        orderTypeHash.slice(2),
        orderComponents.offerer.slice(2).padStart(64, "0"),
        orderComponents.zone.slice(2).padStart(64, "0"),
        offerHash.slice(2),
        considerationHash.slice(2),
        orderComponents.orderType.toString().padStart(64, "0"),
        toBN(orderComponents.startTime).toHexString().slice(2).padStart(64, "0"),
        toBN(orderComponents.endTime).toHexString().slice(2).padStart(64, "0"),
        orderComponents.zoneHash.slice(2),
        orderComponents.salt.slice(2).padStart(64, "0"),
        orderComponents.conduitKey.slice(2).padStart(64, "0"),
        toBN(orderComponents.counter).toHexString().slice(2).padStart(64, "0"),
      ].join("")
  );

  return derivedOrderHash;
};

export const buildResolver = (
  orderIndex: number,
  side: 0 | 1,
  index: number,
  identifier: BigNumber,
  criteriaProof: string[]
): CriteriaResolver => ({
  orderIndex,
  side,
  index,
  identifier,
  criteriaProof,
});
