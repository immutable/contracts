// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { addressOf, encodeImageHash, walletSign, signAndExecuteMetaTx } from './utils/helpers'
import { CustomModule__factory, MainModule } from '../src/gen/typechain'
import { startup } from 'src/gen/adapter'

describe('Wallet Factory', function () {
//  let salts: string[] = []

  async function setupStartupFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, acc1] = await ethers.getSigners()

    const WalletFactory = await ethers.getContractFactory('Factory')
    const factory = await WalletFactory.deploy(owner.address, owner.address)

    const LatestWalletImplLocator = await ethers.getContractFactory('LatestWalletImplLocator')
    const latestWalletImplLocator = await LatestWalletImplLocator.deploy(owner.address, owner.address)

    const StartupWalletImpl= await ethers.getContractFactory('StartupWalletImpl')
    const startupWalletImpl = await StartupWalletImpl.deploy(latestWalletImplLocator.address)

    const MainModule = await ethers.getContractFactory('MainModuleMockV1')
    const mainModuleV1 = await MainModule.deploy(factory.address, startupWalletImpl.address)

    await latestWalletImplLocator.changeWalletImplementation(mainModuleV1.address)




    const salt = encodeImageHash(1, [{ weight: 1, address: owner.address }])


    return {
      owner,
      acc1,
      factory,
      mainModuleV1,
      startupWalletImpl,
      salt,
      latestWalletImplLocator

    }
  }

  describe('Startup', function () {

    it('Should deploy wallet proxy to the expected address', async function () {
      const { factory, startupWalletImpl, salt } = await loadFixture(setupStartupFixture)

      expect(await factory.deploy(startupWalletImpl.address, salt))
          .to.emit(factory, 'WalletDeployed')
          .withArgs(addressOf(factory.address, startupWalletImpl.address, salt), startupWalletImpl.address, salt)

      const deployedContract = await ethers.getContractAt(
          'MainModuleMockV1',
          addressOf(factory.address, startupWalletImpl.address, salt)
      )

      // Attempt a function call to check that the contract has been deployed.
      // This will proxy through to the uninitialised MainModule
      // initial wallet nonce = 0
      expect(await deployedContract.nonce()).to.equal(0)

      // Check the wallet implementation version
      expect(await deployedContract.version()).to.equal(1)
    })

    it('Get implementation before first transaction should indicate startup', async function () {
      const { factory, startupWalletImpl, salt } = await loadFixture(setupStartupFixture)

      await factory.deploy(startupWalletImpl.address, salt)
      const deployedContract = await ethers.getContractAt(
          'IWalletProxy',
          addressOf(factory.address, startupWalletImpl.address, salt)
        )

        expect(await deployedContract.PROXY_getImplementation()).to.equal(startupWalletImpl.address)
    })


    it('Get implementation after first transaction should indicate implementation', async function () {
      const { factory, mainModuleV1, startupWalletImpl} = await loadFixture(setupStartupFixture)

      const acc = ethers.Wallet.createRandom()
      const salt = encodeImageHash(1, [{ weight: 1, address: acc.address }])

      // Deploy the proxy
      await factory.deploy(startupWalletImpl.address, salt)

      const deployedAddress = addressOf(factory.address, startupWalletImpl.address, salt)

      const wallet = (await ethers.getContractAt('MainModuleMockV1', deployedAddress)) as MainModule
      const networkId = (await ethers.provider.getNetwork()).chainId

      const initNonce = ethers.constants.Zero

      const valA = 7
      const valB = '0x0d'
      const CallReceiver = await ethers.getContractFactory('CallReceiverMock')
      const callReceiver = await CallReceiver.deploy()

      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: ethers.constants.Two.pow(21),
        target: callReceiver.address,
        value: ethers.constants.Zero,
        data: callReceiver.interface.encodeFunctionData('testCall', [valA, valB])
      }

      // check wallet nonce before and after transaction
      expect((await wallet.nonce()).toNumber()).to.equal(0)
      await signAndExecuteMetaTx(wallet, acc, [transaction], networkId, initNonce)
      expect((await wallet.nonce()).toNumber()).to.equal(1)

      // Check that the values in the target contract were altered
      expect(await callReceiver.lastValA()).to.equal(valA)
      expect(await callReceiver.lastValB()).to.equal(valB)

      // Check that the get implementation now points to the main module.
      const deployedProxy = await ethers.getContractAt('IWalletProxy', deployedAddress)

      // Check that get implementation returns the address of main
      expect(await deployedProxy.PROXY_getImplementation()).to.equal(mainModuleV1.address)
    })




    it('Should be able to upgrade implementation contracts', async function () {
      const { factory, startupWalletImpl } = await loadFixture(setupStartupFixture)

      const acc = ethers.Wallet.createRandom()
      const salt = encodeImageHash(1, [{ weight: 1, address: acc.address }])


      //console.log("Deploy wallet proxy using MainModuleMockV1")
      await factory.deploy(startupWalletImpl.address, salt)
      const deployedAddress = addressOf(factory.address, startupWalletImpl.address, salt)

      const wallet = await ethers.getContractAt('MainModuleMockV1', deployedAddress)
      // Check the wallet implementation version
      expect(await wallet.version()).to.equal(1)

      const walletMainModule = await ethers.getContractAt('MainModuleMockV1', deployedAddress) as MainModule


      //console.log("Deploy MainModuleMockV2")
      const MainModuleV2 = await ethers.getContractFactory('MainModuleMockV2')
      const mainModuleV2 = await MainModuleV2.deploy(factory.address, startupWalletImpl.address)

      // console.log("Upgrade wallet proxy to using MainModuleMockV2")
      const networkId = (await ethers.provider.getNetwork()).chainId
      // upgrade implementation tx
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: ethers.constants.Two.pow(21),
        target: wallet.address,
        value: ethers.constants.Zero,
        data: wallet.interface.encodeFunctionData('updateImplementation', [mainModuleV2.address])
      }

      let nonce = await wallet.nonce()
      await signAndExecuteMetaTx(walletMainModule, acc, [transaction], networkId, nonce)

      // Check that get implementation returns the address of main
      const walletAsProxy = await ethers.getContractAt('IWalletProxy', deployedAddress)
      expect(await walletAsProxy.PROXY_getImplementation()).to.equal(mainModuleV2.address)

      // Check the wallet implementation version
      expect(await wallet.version()).to.equal(2)


      // Now check that a transaction can be executed
      //console.log("Execute a function call to Call Receiver Mock")
      const valA = 7
      const valB = '0x0d'
      const CallReceiver = await ethers.getContractFactory('CallReceiverMock')
      const callReceiver = await CallReceiver.deploy()
      nonce = await wallet.nonce()

      const transaction2 = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: ethers.constants.Two.pow(21),
        target: callReceiver.address,
        value: ethers.constants.Zero,
        data: callReceiver.interface.encodeFunctionData('testCall', [valA, valB])
      }
      await signAndExecuteMetaTx(walletMainModule, acc, [transaction2], networkId, nonce)

      // Check that the values in the target contract were altered
      expect(await callReceiver.lastValA()).to.equal(valA)
      expect(await callReceiver.lastValB()).to.equal(valB)
    })


    it('Deploying using upgrade should work', async function () {
      const { factory, startupWalletImpl, latestWalletImplLocator } = await loadFixture(setupStartupFixture)

      const MainModuleV2 = await ethers.getContractFactory('MainModuleMockV2')
      const mainModuleV2 = await MainModuleV2.deploy(factory.address, startupWalletImpl.address)
      
      await latestWalletImplLocator.changeWalletImplementation(mainModuleV2.address)


      const acc = ethers.Wallet.createRandom()
      const salt = encodeImageHash(1, [{ weight: 1, address: acc.address }])


      //console.log("Deploy wallet proxy using MainModuleMockV2")
      await factory.deploy(startupWalletImpl.address, salt)
      const deployedAddress = addressOf(factory.address, startupWalletImpl.address, salt)

      const wallet = await ethers.getContractAt('MainModuleMockV2', deployedAddress)
      // Check the wallet implementation version
      expect(await wallet.version()).to.equal(2)

      // Check that get implementation returns the address of main
      const walletAsProxy = await ethers.getContractAt('IWalletProxy', deployedAddress)
      expect(await walletAsProxy.PROXY_getImplementation()).to.equal(startupWalletImpl.address)

      // Now check that a transaction can be executed
      //console.log("Execute a function call to Call Receiver Mock")
      const walletMainModule = await ethers.getContractAt('MainModuleMockV1', deployedAddress) as MainModule
      const valA = 7
      const valB = '0x0d'
      const CallReceiver = await ethers.getContractFactory('CallReceiverMock')
      const callReceiver = await CallReceiver.deploy()
      let nonce = await wallet.nonce()
      const networkId = (await ethers.provider.getNetwork()).chainId

      const transaction2 = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: ethers.constants.Two.pow(21),
        target: callReceiver.address,
        value: ethers.constants.Zero,
        data: callReceiver.interface.encodeFunctionData('testCall', [valA, valB])
      }
      await signAndExecuteMetaTx(walletMainModule, acc, [transaction2], networkId, nonce)

      // Check that the values in the target contract were altered
      expect(await callReceiver.lastValA()).to.equal(valA)
      expect(await callReceiver.lastValB()).to.equal(valB)

      // Check that get implementation returns the address of main
      expect(await walletAsProxy.PROXY_getImplementation()).to.equal(mainModuleV2.address)
    })




    it('Should be able to execute multiple meta transactions', async function () {
      const { factory, startupWalletImpl } = await loadFixture(setupStartupFixture)

      const acc = ethers.Wallet.createRandom()
      const salt = encodeImageHash(1, [{ weight: 1, address: acc.address }])


      //console.log("Deploy wallet proxy using MainModuleMockV1")
      await factory.deploy(startupWalletImpl.address, salt)
      const deployedAddress = addressOf(factory.address, startupWalletImpl.address, salt)

      const walletMainModule = await ethers.getContractAt('MainModuleMockV1', deployedAddress) as MainModule

      // Now check that a transaction can be executed
      // This will be authenticated based on the deployed address
      const valA = 7
      const valB = '0x0d'
      const CallReceiver = await ethers.getContractFactory('CallReceiverMock')
      const callReceiver = await CallReceiver.deploy()

      const networkId = (await ethers.provider.getNetwork()).chainId
      let nonce = await walletMainModule.nonce()
      let transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: ethers.constants.Two.pow(21),
        target: callReceiver.address,
        value: ethers.constants.Zero,
        data: callReceiver.interface.encodeFunctionData('testCall', [valA, valB])
      }
      await signAndExecuteMetaTx(walletMainModule, acc, [transaction], networkId, nonce)

      // Check that the values in the target contract were altered
      expect(await callReceiver.lastValA()).to.equal(valA)
      expect(await callReceiver.lastValB()).to.equal(valB)


      // Now check that a second transaction can be executed
      // This will be authenticated solely based on the image Hash
      const valC = 6
      const valD = '0x053456'

      nonce = await walletMainModule.nonce()
      transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: ethers.constants.Two.pow(21),
        target: callReceiver.address,
        value: ethers.constants.Zero,
        data: callReceiver.interface.encodeFunctionData('testCall', [valC, valD])
      }
      await signAndExecuteMetaTx(walletMainModule, acc, [transaction], networkId, nonce)

      // Check that the values in the target contract were altered
      expect(await callReceiver.lastValA()).to.equal(valC)
      expect(await callReceiver.lastValB()).to.equal(valD)
    })


    it('Check isSignatureValid before the first transaction', async function () {
      const { factory, startupWalletImpl } = await loadFixture(setupStartupFixture)

      const acc = ethers.Wallet.createRandom()
      const salt = encodeImageHash(1, [{ weight: 1, address: acc.address }])


      //console.log("Deploy wallet proxy using MainModuleMockV1")
      await factory.deploy(startupWalletImpl.address, salt)
      const deployedAddress = addressOf(factory.address, startupWalletImpl.address, salt)

      const wallet = await ethers.getContractAt('MainModuleMockV1', deployedAddress)
      const walletMainModule = await ethers.getContractAt('MainModuleMockV1', deployedAddress) as MainModule

      expect(await wallet.version()).to.equal(1)

      const networkId = (await ethers.provider.getNetwork()).chainId

      const data = await ethers.utils.randomBytes(95)
      let messageSubDigest = ethers.utils.solidityPack(
        ['string', 'uint256', 'address', 'bytes'],
        ['\x19\x01', networkId, wallet.address, ethers.utils.keccak256(data)]
      )

      const hash = ethers.utils.keccak256(data)
      const hashSubDigest = ethers.utils.solidityPack(
        ['string', 'uint256', 'address', 'bytes'],
        ['\x19\x01', networkId, wallet.address, ethers.utils.solidityPack(['bytes32'], [hash])]
      )

      let signature = await walletSign(acc, messageSubDigest)
      let isValidSigFuncSelector = await wallet['isValidSignature(bytes,bytes)'](data, signature)
      expect(parseInt(isValidSigFuncSelector, 16)).to.equal(0x20c13b0b)

      signature = await walletSign(acc, hashSubDigest)
      isValidSigFuncSelector = await wallet['isValidSignature(bytes32,bytes)'](hash, signature)
      expect(parseInt(isValidSigFuncSelector, 16)).to.equal(0x1626ba7e)
    })

  })
})

