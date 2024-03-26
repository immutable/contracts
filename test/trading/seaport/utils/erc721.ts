import { expect } from "chai";
import hre from "hardhat";

import { getOfferOrConsiderationItem, randomBN } from "./encoding";

import type { TestERC721 } from "../../../../typechain-types";
import type { BigNumberish, BigNumber, Contract, Wallet } from "ethers";

export async function deployERC721(): Promise<TestERC721> {
  const erc721Factory = await hre.ethers.getContractFactory("TestERC721");
  const erc721 = (await erc721Factory.deploy()) as TestERC721;
  return erc721.deployed();
}

export async function mint721(erc721: TestERC721, signer: Wallet | Contract): Promise<BigNumber> {
  const nftId = randomBN();
  await erc721.mint(signer.address, nftId);
  return nftId;
}

export async function set721ApprovalForAll(erc721: TestERC721, signer: Wallet, spender: string, approved = true) {
  return expect(erc721.connect(signer).setApprovalForAll(spender, approved))
    .to.emit(erc721, "ApprovalForAll")
    .withArgs(signer.address, spender, approved);
}

export async function mintAndApprove721(erc721: TestERC721, signer: Wallet, spender: string): Promise<BigNumber> {
  await set721ApprovalForAll(erc721, signer, spender, true);
  return mint721(erc721, signer);
}

export async function getTestItem721(
  tokenAddress: string,
  identifierOrCriteria: BigNumberish,
  startAmount: BigNumberish = 1,
  endAmount: BigNumberish = 1,
  recipient?: string
) {
  return getOfferOrConsiderationItem(2, tokenAddress, identifierOrCriteria, startAmount, endAmount, recipient);
}
export function getTestItem721WithCriteria(
  tokenAddress: string,
  identifierOrCriteria: BigNumberish,
  startAmount: BigNumberish = 1,
  endAmount: BigNumberish = 1,
  recipient?: string
) {
  return getOfferOrConsiderationItem(4, tokenAddress, identifierOrCriteria, startAmount, endAmount, recipient);
}
