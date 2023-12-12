import { ethers as hardhat, expect } from 'hardhat'
import { ethers } from 'ethers'
import { keccak256, randomBytes, toUtf8Bytes } from 'ethers/lib/utils'
import { ImmutableSigner, ImmutableSigner__factory } from '../src'
import { ethSign } from './utils'

describe('ImmutableSigner', () => {
  let deployerEOA: ethers.Signer
  let rootAdminEOA: ethers.Signer
  let signerAdminEOA: ethers.Signer
  let signerEOA: ethers.Signer
  let randomEOA: ethers.Signer

  let immutableSigner: ImmutableSigner

  const ERC1271_OK = '0x1626ba7e'
  const ERC1271_INVALID = '0x00000000'

  beforeEach(async () => {
    ;[deployerEOA, rootAdminEOA, signerAdminEOA, signerEOA, randomEOA] = await hardhat.getSigners()

    immutableSigner = await new ImmutableSigner__factory()
      .connect(deployerEOA)
      .deploy(await rootAdminEOA.getAddress(), await signerAdminEOA.getAddress(), await signerEOA.getAddress())
  })

  describe('isValidSignature', () => {
    it('Should return ERC1271_MAGICVALUE_BYTES32 for a hash signed by the primary signer', async () => {
      const data = '0x00'
      const hash = keccak256(data)
      const signature = ethSign(signerEOA as ethers.Wallet, hash, true)

      expect(await immutableSigner.isValidSignature(hash, signature)).to.equal(ERC1271_OK)
    })

    it('Should return 0 for a hash signed by a random signer', async () => {
      const data = '0x00'
      const hash = keccak256(data)
      const signature = ethSign(randomEOA as ethers.Wallet, hash, true)

      expect(await immutableSigner.isValidSignature(hash, signature)).to.equal(ERC1271_INVALID)
    })

    it('Should return 0 for a random signature', async () => {
      const data = '0x00'
      const hash = keccak256(data)

      // Random input hence could fail with a couple different messages
      await expect(immutableSigner.isValidSignature(hash, randomBytes(66))).to.be.reverted
    })

    it('Should return 0 for a random 16 byte signature', async () => {
      const data = '0x00'
      const hash = keccak256(data)

      await expect(immutableSigner.isValidSignature(hash, randomBytes(16))).to.be.revertedWith(
        'SignatureValidator#recoverSigner: invalid signature length'
      )
    })

    it('Should return 0 for a 0 byte signature', async () => {
      const data = '0x00'
      const hash = keccak256(data)

      await expect(immutableSigner.isValidSignature(hash, [])).to.be.revertedWith(
        'SignatureValidator#recoverSigner: invalid signature length'
      )
    })
  })

  describe('updateSigner', () => {
    it('Should immediately update the primary signer', async () => {
      const data = '0x00'
      const hash = keccak256(data)

      const randomEOASignature = ethSign(randomEOA as ethers.Wallet, hash, true)

      await immutableSigner.connect(signerAdminEOA).updateSigner(await randomEOA.getAddress())

      expect(await immutableSigner.isValidSignature(hash, randomEOASignature)).to.equal(ERC1271_OK)
    })

    it('Should immediately expire the previous primary signer', async () => {
      const data = '0x00'
      const hash = keccak256(data)

      const signerEOASignature = ethSign(signerEOA as ethers.Wallet, hash, true)

      await immutableSigner.connect(signerAdminEOA).updateSigner(await randomEOA.getAddress())

      expect(await immutableSigner.isValidSignature(hash, signerEOASignature)).to.equal(ERC1271_INVALID)
    })

    it('Should immediately expire the previous rollover signer', async () => {
      // Set a rollover signer and make sure it's valid
      await immutableSigner.connect(signerAdminEOA).updateSignerWithRolloverPeriod(await randomEOA.getAddress(), 2)

      const data = '0x00'
      const hash = keccak256(data)
      const signerEOASignature = ethSign(signerEOA as ethers.Wallet, hash, true)
      expect(await immutableSigner.isValidSignature(hash, signerEOASignature)).to.equal(ERC1271_OK)

      // Still within the valid time range
      await hardhat.provider.send('evm_increaseTime', [2])
      await hardhat.provider.send('evm_mine', [])
      await immutableSigner.connect(signerAdminEOA).updateSigner(await randomEOA.getAddress())
      expect(await immutableSigner.isValidSignature(hash, signerEOASignature)).to.equal(ERC1271_INVALID)
    })

    it('Should not allow changes from EOAs without SIGNER_ADMIN_ROLE', async () => {
      const randomAddress = (await randomEOA.getAddress()).toLowerCase()

      await expect(
        immutableSigner.connect(randomEOA).updateSigner(await randomEOA.getAddress(), { gasLimit: 300_000 })
      ).to.be.revertedWith(
        `AccessControl: account ${randomAddress} is missing role ${keccak256(toUtf8Bytes('SIGNER_ADMIN_ROLE'))}`
      )
    })
  })

  describe('updateSignerWithRolloverPeriod', () => {
    it('Should allow both the new signer and the rollover signer to be used', async () => {
      await immutableSigner.connect(signerAdminEOA).updateSignerWithRolloverPeriod(await randomEOA.getAddress(), 2)

      const data = '0x00'
      const hash = keccak256(data)
      const randomEOASignature = ethSign(randomEOA as ethers.Wallet, hash, true)
      const signerEOASignature = ethSign(signerEOA as ethers.Wallet, hash, true)

      // Within the valid time range
      await hardhat.provider.send('evm_increaseTime', [2])
      await hardhat.provider.send('evm_mine', [])
      expect(await immutableSigner.isValidSignature(hash, randomEOASignature)).to.equal(ERC1271_OK)
      expect(await immutableSigner.isValidSignature(hash, signerEOASignature)).to.equal(ERC1271_OK)
    })

    it('Should expire the rollover signer after the specified timestamp', async () => {
      await immutableSigner.connect(signerAdminEOA).updateSignerWithRolloverPeriod(await randomEOA.getAddress(), 1)

      const data = '0x00'
      const hash = keccak256(data)
      const signerEOASignature = ethSign(signerEOA as ethers.Wallet, hash, true)

      // After the valid time range
      await hardhat.provider.send('evm_increaseTime', [2])
      await hardhat.provider.send('evm_mine', [])
      expect(await immutableSigner.isValidSignature(hash, signerEOASignature)).to.equal(ERC1271_INVALID)
    })

    it('Should allow the primary signer after the specified rollover timestamp', async () => {
      await immutableSigner.connect(signerAdminEOA).updateSignerWithRolloverPeriod(await randomEOA.getAddress(), 1)

      const data = '0x00'
      const hash = keccak256(data)
      const randomEOASignature = ethSign(randomEOA as ethers.Wallet, hash, true)

      // After the valid time range
      await hardhat.provider.send('evm_increaseTime', [2])
      await hardhat.provider.send('evm_mine', [])
      expect(await immutableSigner.isValidSignature(hash, randomEOASignature)).to.equal(ERC1271_OK)
    })

    it('Should not allow signers other than the primary and rollover to be used during rollover', async () => {
      await immutableSigner.connect(signerAdminEOA).updateSignerWithRolloverPeriod(await randomEOA.getAddress(), 2)

      const data = '0x00'
      const hash = keccak256(data)

      const signatures = [
        ethSign(deployerEOA as ethers.Wallet, hash, true),
        ethSign(rootAdminEOA as ethers.Wallet, hash, true),
        ethSign(signerAdminEOA as ethers.Wallet, hash, true)
      ]

      // Within rollover
      await hardhat.provider.send('evm_increaseTime', [2])
      await hardhat.provider.send('evm_mine', [])
      for (const signature of signatures) {
        expect(await immutableSigner.isValidSignature(hash, signature)).to.equal(ERC1271_INVALID)
      }
    })
  })
})
