import { expect } from "chai";
import { constants, utils } from "ethers";
import { keccak256, recoverAddress } from "ethers/lib/utils";
import { ethers } from "hardhat";

import { calculateOrderHash, convertSignatureToEIP2098, randomHex, toBN } from "./encoding";

import type { ConsiderationItem, OfferItem, OrderComponents } from "./types";
import type { Contract, Wallet } from "ethers";
import { ImmutableSeaport, TestZone } from "../../../typechain-types";
import { getBulkOrderTree } from "./eip712/bulk-orders";
import { ReceivedItemStruct } from "../../../typechain-types/contracts/ImmutableSeaport";
import { CONSIDERATION_EIP712_TYPE, EIP712_DOMAIN, SIGNED_ORDER_EIP712_TYPE, getCurrentTimeStamp } from "./signedZone";

const orderType = {
  OrderComponents: [
    { name: "offerer", type: "address" },
    { name: "zone", type: "address" },
    { name: "offer", type: "OfferItem[]" },
    { name: "consideration", type: "ConsiderationItem[]" },
    { name: "orderType", type: "uint8" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "zoneHash", type: "bytes32" },
    { name: "salt", type: "uint256" },
    { name: "conduitKey", type: "bytes32" },
    { name: "counter", type: "uint256" },
  ],
  OfferItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  ConsiderationItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
};

export async function getAndVerifyOrderHash(marketplace: ImmutableSeaport, orderComponents: OrderComponents) {
  // const orderHash = await marketplace.getOrderHash(orderComponents);
  const derivedOrderHash = calculateOrderHash(orderComponents);
  // expect(orderHash).to.equal(derivedOrderHash);
  return derivedOrderHash;
}

export function getDomainData(marketplaceAddress: string, chainId: string) {
  return {
    name: "ImmutableSeaport",
    version: "1.5",
    chainId,
    verifyingContract: marketplaceAddress,
  };
}

export async function signOrder(
  marketplace: ImmutableSeaport,
  orderComponents: OrderComponents,
  signer: Wallet | Contract,
  chainId,
  domainSeparator,
) {
  // const chainId = await signer.getChainId();
  const signature = await signer._signTypedData(
    { ...getDomainData(marketplace.address, chainId), verifyingContract: marketplace.address },
    orderType,
    orderComponents
  );

  const orderHash = calculateOrderHash(orderComponents);

  // const { domainSeparator } = await marketplace.information();
  console.log(`domainSeparator: ${domainSeparator}`)
  const digest = keccak256(`0x1901${domainSeparator.slice(2)}${orderHash.slice(2)}`);
  const recoveredAddress = recoverAddress(digest, signature);

  expect(recoveredAddress).to.equal(signer.address);

  return signature;
}

const signBulkOrder = async (
  marketplace: ImmutableSeaport,
  orderComponents: OrderComponents[],
  signer: Wallet | Contract,
  startIndex = 0,
  height?: number,
  extraCheap?: boolean
) => {
  const chainId = await signer.getChainId();
  const tree = getBulkOrderTree(orderComponents, startIndex, height);
  const bulkOrderType = tree.types;
  const chunks = tree.getDataToSign();
  let signature = await signer._signTypedData(getDomainData(marketplace.address, chainId), bulkOrderType, {
    tree: chunks,
  });

  if (extraCheap) {
    signature = convertSignatureToEIP2098(signature);
  }

  const proofAndSignature = tree.getEncodedProofAndSignature(startIndex, signature);

  const orderHash = tree.getBulkOrderHash();

  const { domainSeparator } = await marketplace.information();
  const digest = keccak256(`0x1901${domainSeparator.slice(2)}${orderHash.slice(2)}`);
  const recoveredAddress = recoverAddress(digest, signature);

  expect(recoveredAddress).to.equal(signer.address);

  // Verify each individual order
  for (const components of orderComponents) {
    const individualOrderHash = await getAndVerifyOrderHash(marketplace, components);
    const digest = keccak256(`0x1901${domainSeparator.slice(2)}${individualOrderHash.slice(2)}`);
    const individualOrderSignature = await signer._signTypedData(
      getDomainData(marketplace.address, chainId),
      orderType,
      components
    );
    const recoveredAddress = recoverAddress(digest, individualOrderSignature);
    expect(recoveredAddress).to.equal(signer.address);
  }

  return proofAndSignature;
};

export async function createOrder(
  marketplace: ImmutableSeaport,
  offerer: Wallet | Contract,
  zone: TestZone | Wallet | undefined | string = undefined,
  offer: OfferItem[],
  consideration: ConsiderationItem[],
  orderType: number,
  chainId: number,
  domainSeperator: string,
  timeFlag?: string | null,
  signer?: Wallet,
  zoneHash = constants.HashZero,
  conduitKey = constants.HashZero,
  extraCheap = false,
  useBulkSignature = false,
  bulkSignatureIndex?: number,
  bulkSignatureHeight?: number
) {
  // const counter = await marketplace.getCounter(offerer.address);
  const counter = ethers.BigNumber.from(0);

  const salt = !extraCheap ? randomHex() : constants.HashZero;
  const startTime = timeFlag !== "NOT_STARTED" ? 0 : toBN("0xee00000000000000000000000000");
  const endTime = timeFlag !== "EXPIRED" ? toBN("0xff00000000000000000000000000") : 1;

  const orderParameters = {
    offerer: offerer.address,
    zone: !extraCheap ? (zone as Wallet).address ?? zone : constants.AddressZero,
    offer,
    consideration,
    totalOriginalConsiderationItems: consideration.length,
    orderType,
    zoneHash,
    salt,
    conduitKey,
    startTime,
    endTime,
  };

  const orderComponents = {
    ...orderParameters,
    counter,
  };

  const orderHash = await getAndVerifyOrderHash(marketplace, orderComponents);

  // const { isValidated, isCancelled, totalFilled, totalSize } = await marketplace.getOrderStatus(orderHash);
  // console.log(`isValidated: ${isValidated}, isCancelled: ${isCancelled}, totalFilled: ${totalFilled}, totalSize: ${totalSize}`);

  // expect(isCancelled).to.equal(false);

  const orderStatus = {
    isValidated: false,
    isCancelled: false,
    totalFilled: "0",
    totalSize: "0",
  };

  const flatSig = await signOrder(marketplace, orderComponents, signer ?? offerer, chainId, domainSeperator);

  const order = {
    parameters: orderParameters,
    signature: !extraCheap ? flatSig : convertSignatureToEIP2098(flatSig),
    numerator: 1, // only used for advanced orders
    denominator: 1, // only used for advanced orders
    extraData: "0x", // only used for advanced orders
  };

  if (useBulkSignature) {
    order.signature = await signBulkOrder(
      marketplace,
      [orderComponents],
      signer ?? offerer,
      bulkSignatureIndex,
      bulkSignatureHeight,
      extraCheap
    );

    // Verify bulk signature length
    expect(order.signature.slice(2).length / 2, "bulk signature length should be valid (98 < length < 837)")
      .to.be.gt(98)
      .and.lt(837);
    expect(
      (order.signature.slice(2).length / 2 - 67) % 32,
      "bulk signature length should be valid ((length - 67) % 32 < 2)"
    ).to.be.lt(2);
  }

  // How much ether (at most) needs to be supplied when fulfilling the order
  const value = offer
    .map((x) => (x.itemType === 0 ? (x.endAmount.gt(x.startAmount) ? x.endAmount : x.startAmount) : toBN(0)))
    .reduce((a, b) => a.add(b), toBN(0))
    .add(
      consideration
        .map((x) => (x.itemType === 0 ? (x.endAmount.gt(x.startAmount) ? x.endAmount : x.startAmount) : toBN(0)))
        .reduce((a, b) => a.add(b), toBN(0))
    );

  return {
    order,
    orderHash,
    value,
    orderStatus,
    orderComponents,
    startTime,
    endTime,
  };
}

export async function generateSip7Signature(
  consideration: ConsiderationItem[],
  orderHash: string,
  fulfillerAddress: string,
  immutableSignedZoneAddress: string,
  immutableSigner: Wallet,
  chainId: number,
) {
  const considerationAsReceivedItem: ReceivedItemStruct[] = consideration.map((item) => {
    return {
      amount: item.startAmount,
      identifier: item.identifierOrCriteria,
      itemType: item.itemType,
      recipient: item.recipient,
      token: item.token,
    };
  });

  // const expiration = (await getCurrentTimeStamp()) + 100;
  const expiration = 1735653600;
  const considerationHash = utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
    consideration: considerationAsReceivedItem,
  });

  const context = utils.solidityPack(["bytes", "bytes[]"], [considerationHash, [orderHash]]);

  const signedOrder = {
    fulfiller: fulfillerAddress,
    expiration,
    orderHash,
    context,
  };

  const signature = await immutableSigner._signTypedData(
    EIP712_DOMAIN(chainId, immutableSignedZoneAddress),
    SIGNED_ORDER_EIP712_TYPE,
    signedOrder
  );

  let packed =  utils.solidityPack(
    ["bytes1", "address", "uint64", "bytes", "bytes"],
    [0, fulfillerAddress, expiration, convertSignatureToEIP2098(signature), context]
  );

  // console.log(`fullfiller: ${fulfillerAddress}`)
  // console.log(`Packed signature: ${packed}`)

  return packed
}

export async function generateSip7SignatureLoadTest(
  consideration: ConsiderationItem[],
  orderHash: string,
  immutableSignedZoneAddress: string,
  immutableSigner: Wallet
) {
  const considerationAsReceivedItem: ReceivedItemStruct[] = consideration.map((item) => {
    return {
      amount: item.startAmount,
      identifier: item.identifierOrCriteria,
      itemType: item.itemType,
      recipient: item.recipient,
      token: item.token,
    };
  });

  const expiration = (await getCurrentTimeStamp()) + 100;
  const considerationHash = utils._TypedDataEncoder.hashStruct("Consideration", CONSIDERATION_EIP712_TYPE, {
    consideration: considerationAsReceivedItem,
  });

  const context = utils.solidityPack(["bytes", "bytes[]"], [considerationHash, [orderHash]]);

  const signedOrder = {
    fulfiller: fulfillerAddress,
    expiration,
    orderHash,
    context,
  };

  const chainId = (await ethers.provider.getNetwork()).chainId;
  const signature = await immutableSigner._signTypedData(
    EIP712_DOMAIN(chainId, immutableSignedZoneAddress),
    SIGNED_ORDER_EIP712_TYPE,
    signedOrder
  );

  // Insert 
  let packed =  utils.solidityPack(
    ["bytes1", "uint64", "bytes", "bytes"],
    [0, expiration, convertSignatureToEIP2098(signature), context]
  );
  
  return packed
}
