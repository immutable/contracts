import { expect } from 'chai';
import { ethers } from 'hardhat';

describe("Asset", function () {

  it("Should be able to mint successfully with a valid blueprint", async function () {
   
    const [owner] = await ethers.getSigners();

    const Asset = await ethers.getContractFactory("Asset");

    const o = owner.address;
    const name = 'Gods Unchained';
    const symbol = 'GU';
    const imx = owner.address;
    const mintable = await Asset.deploy(o, name, symbol, imx);

    const tokenID = '123';
    const blueprint = '1000';
    const blob = toHex(`{${tokenID}}:{${blueprint}}`);

    await mintable.mintFor(owner.address, 1, blob);

    const oo = await mintable.ownerOf(tokenID);

    expect(oo).to.equal(owner.address);

    const bp = await mintable.blueprints(tokenID);

    expect(fromHex(bp)).to.equal(blueprint);

  });

  it("Should be able to mint successfully with an empty blueprint", async function () {
   
    const [owner] = await ethers.getSigners();

    const Asset = await ethers.getContractFactory("Asset");

    const o = owner.address;
    const name = 'Gods Unchained';
    const symbol = 'GU';
    const imx = owner.address;
    const mintable = await Asset.deploy(o, name, symbol, imx);

    const tokenID = '123';
    const blueprint = '';
    const blob = toHex(`{${tokenID}}:{${blueprint}}`);

    await mintable.mintFor(owner.address, 1, blob);

    const bp = await mintable.blueprints(tokenID);

    expect(fromHex(bp)).to.equal(blueprint);

  });

  it("Should not be able to mint successfully with an invalid blueprint", async function () {
   
    const [owner] = await ethers.getSigners();

    const Asset = await ethers.getContractFactory("Asset");

    const o = owner.address;
    const name = 'Gods Unchained';
    const symbol = 'GU';
    const imx = owner.address;
    const mintable = await Asset.deploy(o, name, symbol, imx);

    const blob = toHex(`:`);
    await expect(mintable.mintFor(owner.address, 1, blob)).to.be.reverted;

  });
});

function toHex(str: string) {
  let result = '';
  for (let i=0; i < str.length; i++) {
    result += str.charCodeAt(i).toString(16);
  }
  return '0x' + result;
}

function fromHex(str1: string) {
	let hex = str1.toString().substr(2);
	let str = '';
	for (let n = 0; n < hex.length; n += 2) {
		str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
	}
	return str;
 }