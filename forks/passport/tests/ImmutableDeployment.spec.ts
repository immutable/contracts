import { ethers as hardhat } from 'hardhat'
import { ethers } from 'ethers'
import { getContractAddress } from '@ethersproject/address'
import {
  Factory,
  Factory__factory,
  MainModule__factory,
  ImmutableSigner,
  ImmutableSigner__factory,
  LatestWalletImplLocator__factory,
  StartupWalletImpl__factory,
  MainModuleDynamicAuth,
  MainModuleDynamicAuth__factory,
} from '../src'
import {
  encodeImageHash,
  expect,
  addressOf,
  encodeMetaTransactionsData,
  walletMultiSign,
  ethSign,
} from './utils'
import { LatestWalletImplLocator, StartupWalletImpl } from 'src/gen/typechain'

describe('E2E Immutable Wallet Deployment', () => {
  let contractDeployerEOA: ethers.Signer
  let relayerEOA: ethers.Signer

  let userEOA: ethers.Signer
  let immutableEOA: ethers.Signer
  let randomEOA: ethers.Signer
  let adminEOA: ethers.Signer
  let walletDeployerEOA: ethers.Signer

  // All contracts involved in the wallet ecosystem
  let factory: Factory
  let mainModuleDynamicAuth: MainModuleDynamicAuth
  let immutableSigner: ImmutableSigner
  let moduleLocator: LatestWalletImplLocator
  let startupWallet: StartupWalletImpl

  const WALLET_FACTORY_NONCE = 1
  const STARTUP_WALLET_NONCE = 2
  const IMMUTABLE_SIGNER_NONCE = 3
  const LOCATOR_NONCE = 4
  const MAIN_MODULE_DYNAMIC_AUTH_NONCE = 5

  beforeEach(async () => {
    [
      userEOA,
      immutableEOA,
      randomEOA,
      adminEOA,
      walletDeployerEOA,
      relayerEOA,
      contractDeployerEOA
    ] = await hardhat.getSigners()

    await hardhat.provider.send("hardhat_reset", [])

    // Matches the production environment where the first transaction (nonce 0)
    // is used for testing.
    contractDeployerEOA.sendTransaction({ to: ethers.constants.AddressZero, value: 0 })

    // Nonce 1
    factory = await new Factory__factory()
      .connect(contractDeployerEOA)
      .deploy(await adminEOA.getAddress(), await walletDeployerEOA.getAddress())

    // Calculate the locator address ahead of time
    const moduleLocatorAddress = getContractAddress({
      from: await contractDeployerEOA.getAddress(),
      nonce: LOCATOR_NONCE
    })

    // Nonce 2
    startupWallet = await new StartupWalletImpl__factory()
      .connect(contractDeployerEOA)
      .deploy(moduleLocatorAddress)

    // Nonce 3
    immutableSigner = await new ImmutableSigner__factory()
      .connect(contractDeployerEOA)
      .deploy(await adminEOA.getAddress(), await adminEOA.getAddress(), await immutableEOA.getAddress())

    // NOTE: Those could possibly be deployed by a separate account instead.

    // Nonce 4
    moduleLocator = await new LatestWalletImplLocator__factory()
      .connect(contractDeployerEOA)
      .deploy(await adminEOA.getAddress(), await walletDeployerEOA.getAddress())

    // Nonce 5
    mainModuleDynamicAuth = await new MainModuleDynamicAuth__factory()
      .connect(contractDeployerEOA)
      .deploy(factory.address, startupWallet.address)

    // Setup the latest implementation address
    await moduleLocator
      .connect(walletDeployerEOA)
      .changeWalletImplementation(mainModuleDynamicAuth.address)
  })

  it('Should create deterministic contract addresses', async () => {
    // Generate deployed contract addresses offchain from the deployer address
    // and fixed nonces.
    const factoryAddress = getContractAddress({
      from: await contractDeployerEOA.getAddress(),
      nonce: WALLET_FACTORY_NONCE
    })

    const startupWalletAddress = getContractAddress({
      from: await contractDeployerEOA.getAddress(),
      nonce: STARTUP_WALLET_NONCE
    })

    const immutableSignerAddress = getContractAddress({
      from: await contractDeployerEOA.getAddress(),
      nonce: IMMUTABLE_SIGNER_NONCE
    })

    const locatorAddress = getContractAddress({
      from: await contractDeployerEOA.getAddress(),
      nonce: LOCATOR_NONCE
    })

    const mainModuleAddress = getContractAddress({
      from: await contractDeployerEOA.getAddress(),
      nonce: MAIN_MODULE_DYNAMIC_AUTH_NONCE
    })

    // Check they match against the actual deployed addresses
    expect(factory.address).to.equal(factoryAddress)
    expect(mainModuleDynamicAuth.address).to.equal(mainModuleAddress)
    expect(immutableSigner.address).to.equal(immutableSignerAddress)
    expect(startupWallet.address).to.equal(startupWalletAddress)
    expect(moduleLocator.address).to.equal(locatorAddress)
  })

  it('Should execute a transaction signed by the ImmutableSigner', async () => {
    // Deploy wallet
    const walletSalt = encodeImageHash(2, [
      { weight: 1, address: await userEOA.getAddress() },
      { weight: 1, address: immutableSigner.address }
    ])
    const walletAddress = addressOf(factory.address, startupWallet.address, walletSalt)
    const walletDeploymentTx = await factory.connect(walletDeployerEOA).deploy(startupWallet.address, walletSalt)
    await walletDeploymentTx.wait()

    // Connect to the generated user address
    const wallet = MainModule__factory.connect(walletAddress, relayerEOA)

    // Transfer funds to the SCW
    const transferTx = await relayerEOA.sendTransaction({ to: walletAddress, value: 1 })
    await transferTx.wait()

    // Return funds
    const transaction = {
      delegateCall: false,
      revertOnError: true,
      gasLimit: 1000000,
      target: await randomEOA.getAddress(),
      value: 1,
      data: []
    }

    // Build meta-transaction
    const networkId = (await hardhat.provider.getNetwork()).chainId
    const nonce = 0
    const data = encodeMetaTransactionsData(wallet.address, [transaction], networkId, nonce)

    const signature = await walletMultiSign(
      [
        { weight: 1, owner: userEOA as ethers.Wallet },
        // 03 -> Call the address' isValidSignature()
        { weight: 1, owner: immutableSigner.address, signature: (await ethSign(immutableEOA as ethers.Wallet, data)) + '03' }
      ],
      2,
      data,
      false
    )

    const originalBalance = await randomEOA.getBalance();

    const executionTx = await wallet.execute([transaction], nonce, signature)
    await executionTx.wait()

    expect(await randomEOA.getBalance()).to.equal(originalBalance.add(1))
  })

  it('Should execute multiple transactions signed by the ImmutableSigner', async () => {
    // Deploy wallet
    const walletSalt = encodeImageHash(2, [
      { weight: 1, address: await userEOA.getAddress() },
      { weight: 1, address: immutableSigner.address }
    ])
    const walletAddress = addressOf(factory.address, startupWallet.address, walletSalt)
    const walletDeploymentTx = await factory.connect(walletDeployerEOA).deploy(startupWallet.address, walletSalt)
    await walletDeploymentTx.wait()

    // Connect to the generated user address
    const wallet = MainModule__factory.connect(walletAddress, relayerEOA)

    // Transfer funds to the SCW
    const transferTx = await relayerEOA.sendTransaction({ to: walletAddress, value: 5 })
    await transferTx.wait()

    for (const nonce of [0, 1, 2, 3, 4]) {
      // Return funds
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: 1000000,
        target: await randomEOA.getAddress(),
        value: 1,
        data: []
      }

      // Build meta-transaction
      const networkId = (await hardhat.provider.getNetwork()).chainId
      const data = encodeMetaTransactionsData(wallet.address, [transaction], networkId, nonce)

      const signature = await walletMultiSign(
        [
          { weight: 1, owner: userEOA as ethers.Wallet },
          // 03 -> Call the address' isValidSignature()
          { weight: 1, owner: immutableSigner.address, signature: (await ethSign(immutableEOA as ethers.Wallet, data)) + '03' }
        ],
        2,
        data,
        false
      )

      const originalBalance = await randomEOA.getBalance();

      const executionTx = await wallet.execute([transaction], nonce, signature)
      await executionTx.wait()

      expect(await randomEOA.getBalance()).to.equal(originalBalance.add(1))
    }
  })

  it('Should not execute a transaction not signed by the ImmutableSigner', async () => {
    // Deploy wallet
    const walletSalt = encodeImageHash(2, [
      { weight: 1, address: await userEOA.getAddress() },
      { weight: 1, address: immutableSigner.address }
    ])
    const walletAddress = addressOf(factory.address, startupWallet.address, walletSalt)
    const walletDeploymentTx = await factory.connect(walletDeployerEOA).deploy(startupWallet.address, walletSalt)
    await walletDeploymentTx.wait()

    // Connect to the generated user address
    const wallet = MainModule__factory.connect(walletAddress, relayerEOA)

    // Transfer funds to the SCW
    const transferTx = await relayerEOA.sendTransaction({ to: walletAddress, value: 1 })
    await transferTx.wait()

    // Return funds
    const transaction = {
      delegateCall: false,
      revertOnError: true,
      gasLimit: 1000000,
      target: await randomEOA.getAddress(),
      value: 1,
      data: []
    }

    // Build meta-transaction
    const networkId = (await hardhat.provider.getNetwork()).chainId
    const nonce = 0
    const data = encodeMetaTransactionsData(wallet.address, [transaction], networkId, nonce)

    const signature = await walletMultiSign(
      [
        { weight: 1, owner: userEOA as ethers.Wallet },
        { weight: 1, owner: immutableSigner.address, signature: (await ethSign(randomEOA as ethers.Wallet, data)) + '03' }
      ],
      2,
      data,
      false
    )

    await expect(wallet.execute([transaction], nonce, signature)).to.be.revertedWith(
      'ModuleAuth#_signatureValidation: INVALID_SIGNATURE'
    )
  })

  it('Should not execute a transaction signed by the ImmutableSigner with the incorrect data', async () => {
    // Deploy wallet
    const walletSalt = encodeImageHash(2, [
      { weight: 1, address: await userEOA.getAddress() },
      { weight: 1, address: immutableSigner.address }
    ])
    const walletAddress = addressOf(factory.address, startupWallet.address, walletSalt)
    const walletDeploymentTx = await factory.connect(walletDeployerEOA).deploy(startupWallet.address, walletSalt)
    await walletDeploymentTx.wait()

    // Connect to the generated user address
    const wallet = MainModule__factory.connect(walletAddress, relayerEOA)

    // Transfer funds to the SCW
    const transferTx = await relayerEOA.sendTransaction({ to: walletAddress, value: 1 })
    await transferTx.wait()

    // Return funds
    const transaction = {
      delegateCall: false,
      revertOnError: true,
      gasLimit: 1000000,
      target: await relayerEOA.getAddress(),
      value: 1,
      data: []
    }

    // Build meta-transaction
    const networkId = (await hardhat.provider.getNetwork()).chainId
    const nonce = 0
    const data = encodeMetaTransactionsData(wallet.address, [transaction], networkId, nonce)

    const meaninglessDataDisturbance = '05'
    const signature = await walletMultiSign(
      [
        { weight: 1, owner: userEOA as ethers.Wallet },
        // 03 -> Call the address' isValidSignature()
        {
          weight: 1,
          owner: immutableSigner.address,
          signature: (await ethSign(immutableEOA as ethers.Wallet, data + meaninglessDataDisturbance)) + '03'
        }
      ],
      2,
      data,
      false
    )

    await expect(wallet.execute([transaction], nonce, signature)).to.be.revertedWith(
      'ModuleAuth#_signatureValidation: INVALID_SIGNATURE'
    )
  })

  it('Should not execute a transaction signed by an outdated signer', async () => {
    // Deploy wallet
    const walletSalt = encodeImageHash(2, [
      { weight: 1, address: await userEOA.getAddress() },
      { weight: 1, address: immutableSigner.address }
    ])
    const walletAddress = addressOf(factory.address, startupWallet.address, walletSalt)
    const walletDeploymentTx = await factory.connect(walletDeployerEOA).deploy(startupWallet.address, walletSalt)
    await walletDeploymentTx.wait()

    // Connect to the generated user address
    const wallet = MainModule__factory.connect(walletAddress, relayerEOA)

    // Transfer funds to the SCW
    const transferTx = await relayerEOA.sendTransaction({ to: walletAddress, value: 1 })
    await transferTx.wait()

    // Change the signer
    expect(await immutableSigner.connect(adminEOA).updateSigner(await randomEOA.getAddress()))
      .to.emit(immutableSigner, 'SignerUpdated')
      .withArgs(await immutableEOA.getAddress(), await randomEOA.getAddress())

    // Return funds
    const transaction = {
      delegateCall: false,
      revertOnError: true,
      gasLimit: 1000000,
      target: await relayerEOA.getAddress(),
      value: 1,
      data: []
    }

    // Build meta-transaction
    const networkId = (await hardhat.provider.getNetwork()).chainId
    const nonce = 0
    const data = encodeMetaTransactionsData(wallet.address, [transaction], networkId, nonce)

    const signature = await walletMultiSign(
      [
        { weight: 1, owner: userEOA as ethers.Wallet },
        // 03 -> Call the address' isValidSignature()
        {
          weight: 1,
          owner: immutableSigner.address,
          signature: (await ethSign(immutableEOA as ethers.Wallet, data)) + '03'
        }
      ],
      2,
      data,
      false
    )

    await expect(wallet.execute([transaction], nonce, signature)).to.be.revertedWith(
      'ModuleAuth#_signatureValidation: INVALID_SIGNATURE'
    )
  })
})
