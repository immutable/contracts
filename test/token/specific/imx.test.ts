import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';

let token: Contract, ownerSigner: SignerWithAddress, addr1Signer: SignerWithAddress, ownerAddr: string, addr1: string;

describe('IMX Token', function () {
    beforeEach(async function () {
        [ownerSigner, addr1Signer] = await ethers.getSigners();
        ownerAddr = ownerSigner.address;
        addr1 = addr1Signer.address;
        const Token = await ethers.getContractFactory('IMXToken');
        token = await Token.deploy(ownerAddr);
        await token.deployed();
    });

    describe('Given a function call from the owner address', function () {
        describe('When minting tokens to any address', function () {
            it('Then it should update total supply', async function () {
                expect(await token.totalSupply.call({})).to.equal(0);
                expect(await token.mint(ownerAddr, 1));
                expect(await token.totalSupply.call({})).to.equal(1);
                expect(await token.mint(addr1, 10));
                expect(await token.totalSupply.call({})).to.equal(11);
            });

            it('Then it should update their respective token balances', async function () {
                expect(await token.balanceOf(ownerAddr)).to.equal(0);
                expect(await token.mint(ownerAddr, 1));
                expect(await token.balanceOf(ownerAddr)).to.equal(1);
                expect(await token.mint(addr1, 2));
                expect(await token.balanceOf(addr1)).to.equal(2);
            });
        });
    });

    describe('Given a function call from a non-owner address', function () {
        describe('When minting tokens to any address', function () {
            it('Then it should revert the transaction (cannot sign)', async function () {
                expect(await token.totalSupply.call({})).to.equal(0);
                await expect(token.connect(addr1Signer).mint(ownerAddr, 1)).to.be.revertedWith('Caller is not a minter');
                expect(await token.totalSupply.call({})).to.equal(0);
            });
        });
    });

    describe('Given a 20mil cap on token supply', function () {
        describe('When minting tokens that will exceed the supply cap', function () {
            it('Then it should revert the transaction (cap exceeded)', async function () {
                expect(await token.totalSupply.call({})).to.equal(0);
                expect(await token.cap.call({})).to.equal(BigNumber.from('2000000000000000000000000000'));
                await expect(token.mint(ownerAddr, BigNumber.from('2000000000000000000000000001'))).to.be.revertedWith(
                    'cap exceeded',
                );
                expect(await token.totalSupply.call({})).to.equal(0);
            });
        });
    });
});