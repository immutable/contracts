import { ethers as hardhat, web3 } from 'hardhat'
import { ethers } from 'ethers'
import { expect, encodeImageHash, signAndExecuteMetaTx, interfaceIdOf, addressOf } from './utils'

import {
  MainModule,
  MainModuleUpgradable,
  MainModuleDynamicAuth,
  StartupWalletImpl,
  LatestWalletImplLocator,
  Factory,
  Factory__factory,
  MainModule__factory,
  MainModuleUpgradable__factory,
  MainModuleDynamicAuth__factory,
  ERC165CheckerMock__factory,
  StartupWalletImpl__factory,
  LatestWalletImplLocator__factory,
} from '../src'

ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)

const interfaceIds = [
  'IModuleHooks',
  'IERC223Receiver',
  'IERC721Receiver',
  'IERC1155Receiver',
  'IERC1271Wallet',
  'IModuleCalls',
  'IModuleCreator',
  'IModuleUpdate'
]

const dynamicModuleInterfaceIds = [
  'IERC223Receiver',
  'IERC721Receiver',
  'IERC1155Receiver',
  'IERC1271Wallet',
  'IModuleCalls',
  'IModuleUpdate'
]

contract('ERC165', () => {
  // let provider: ethers.providers.Provider
  let signer: ethers.Signer
  let networkId: number

  let factory: Factory
  let mainModule: MainModule
  let moduleUpgradable: MainModuleUpgradable
  let moduleDynamicAuth: MainModuleDynamicAuth
  let startupWalletImpl: StartupWalletImpl
  let moduleLocator: LatestWalletImplLocator

  let owner: ethers.Wallet
  let wallet: MainModule

  let erc165checker

  before(async () => {
    // get signer and provider from hardhat
    signer = (await hardhat.getSigners())[0]
    // provider = hardhat.provider

    // Get network ID
    networkId = process.env.NET_ID ? Number(process.env.NET_ID) : await web3.eth.net.getId()

    // Deploy wallet factory
    factory = await new Factory__factory().connect(signer).deploy(await signer.getAddress(), await signer.getAddress())
    // Startup and Locator
    moduleLocator = await new LatestWalletImplLocator__factory().connect(signer).deploy(await signer.getAddress(), await signer.getAddress())
    startupWalletImpl = await new StartupWalletImpl__factory().connect(signer).deploy(moduleLocator.address)
    // Deploy MainModule
    mainModule = await new MainModule__factory().connect(signer).deploy(factory.address)
    moduleUpgradable = await new MainModuleUpgradable__factory().connect(signer).deploy()
    moduleDynamicAuth = await new MainModuleDynamicAuth__factory().connect(signer).deploy(factory.address, startupWalletImpl.address)
    // Deploy ERC165 Checker
    erc165checker = await new ERC165CheckerMock__factory().connect(signer).deploy()

    // Update the implementation address for the startup wallet
    await moduleLocator.connect(signer).changeWalletImplementation(moduleDynamicAuth.address)
  })

  beforeEach(async () => {
    owner = new ethers.Wallet(ethers.utils.randomBytes(32))
    const salt = encodeImageHash(1, [{ weight: 1, address: owner.address }])
    await factory.deploy(mainModule.address, salt)
    wallet = MainModule__factory.connect(addressOf(factory.address, mainModule.address, salt), signer)
  })

  describe('Implement all interfaces for ERC165 on MainModule', () => {
    interfaceIds.forEach(element => {
      it(`Should return implements ${element} interfaceId`, async () => {
        const interfaceId = interfaceIdOf(new ethers.utils.Interface(artifacts.require(element).abi))
        expect(web3.utils.toBN(interfaceId)).to.not.eq.BN(0)

        const erc165result = await erc165checker.doesContractImplementInterface(wallet.address, interfaceId)
        expect(erc165result).to.be.true
      })
    })
  })
  describe('Implement all interfaces for ERC165 on MainModuleUpgradable', () => {
    beforeEach(async () => {
      const newOwner = new ethers.Wallet(ethers.utils.randomBytes(32))
      const newImageHash = encodeImageHash(1, [{ weight: 1, address: newOwner.address }])
      const newWallet = MainModuleUpgradable__factory.connect(wallet.address, signer)

      const migrateTransactions = [
        {
          delegateCall: false,
          revertOnError: true,
          gasLimit: ethers.constants.Two.pow(21),
          target: wallet.address,
          value: ethers.constants.Zero,
          data: wallet.interface.encodeFunctionData('updateImplementation', [moduleUpgradable.address])
        },
        {
          delegateCall: false,
          revertOnError: true,
          gasLimit: ethers.constants.Two.pow(21),
          target: wallet.address,
          value: ethers.constants.Zero,
          data: newWallet.interface.encodeFunctionData('updateImageHash', [newImageHash])
        }
      ]

      await signAndExecuteMetaTx(wallet, owner, migrateTransactions, networkId)
      wallet = newWallet as unknown as MainModule
    })
    interfaceIds.concat('IModuleAuthUpgradable').forEach(element => {
      it(`Should return implements ${element} interfaceId`, async () => {
        const interfaceId = interfaceIdOf(new ethers.utils.Interface(artifacts.require(element).abi))
        expect(web3.utils.toBN(interfaceId)).to.not.eq.BN(0)

        const erc165result = await erc165checker.doesContractImplementInterface(wallet.address, interfaceId)
        expect(erc165result).to.be.true
      })
    })
  })
  describe('Implement all interfaces for ERC165 on MainModuleDynamicAuth', () => {
    beforeEach(async () => {
      owner = new ethers.Wallet(ethers.utils.randomBytes(32))
      const salt = encodeImageHash(1, [{ weight: 1, address: owner.address }])

      // Bypass the startup contract initialization to make sure the gas costs
      // are low, by pointing directly to the implementation contract.
      await factory.deploy(moduleDynamicAuth.address, salt)
      wallet = MainModule__factory.connect(addressOf(factory.address, moduleDynamicAuth.address, salt), signer)
    })

    // Should implement a fixed set of interfaces
    dynamicModuleInterfaceIds.forEach(id => {
      it(`Should implement the ${id} interface`, async () => {
        const interfaceId = interfaceIdOf(new ethers.utils.Interface(artifacts.require(id).abi))
        expect(web3.utils.toBN(interfaceId)).to.not.eq.BN(0)

        const erc165result = await erc165checker.doesContractImplementInterface(wallet.address, interfaceId)
        expect(erc165result).to.be.true
      })
    })

    // And should not implement other interfaces
    interfaceIds.filter(id => !dynamicModuleInterfaceIds.includes(id)).forEach(id => {
      it(`Should not implement the ${id} interface`, async () => {
        const interfaceId = interfaceIdOf(new ethers.utils.Interface(artifacts.require(id).abi))
        expect(web3.utils.toBN(interfaceId)).to.not.eq.BN(0)

        const erc165result = await erc165checker.doesContractImplementInterface(wallet.address, interfaceId)
        expect(erc165result).to.be.false
      })
    })
  })
  describe('Manually defined interfaces', () => {
    const interfaces = [
      ['ERC165', '0x01ffc9a7'],
      ['ERC721', '0x150b7a02'],
      ['ERC1155', '0x4e2312e0']
    ]

    interfaces.forEach(i => {
      it(`Should implement ${i[0]} interface`, async () => {
        const erc165result = await erc165checker.doesContractImplementInterface(wallet.address, i[1])
        expect(erc165result).to.be.true
      })
    })
  })
})
