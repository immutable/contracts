import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { addressOf, encodeImageHash, encodeMetaTransactionsData, walletMultiSign } from './utils/helpers'

describe('Wallet Factory', function () {
  async function setupFactoryFixture() {
    // Network ID
    const networkId = (await ethers.provider.getNetwork()).chainId

    // Wallet TX
    const optimalGasLimit = ethers.constants.Two.pow(21)

    // Contracts are deployed using the first signer/account by default
    const [owner, executor, acc1] = await ethers.getSigners()

    const WalletFactory = await ethers.getContractFactory('Factory')
    const factory = await WalletFactory.deploy(owner.address, await owner.getAddress())

    const MainModule = await ethers.getContractFactory('MainModuleMock')
    const mainModule = await MainModule.deploy(factory.address)

    const MultiCall = await ethers.getContractFactory('MultiCallDeploy')
    const multiCall = await MultiCall.deploy(owner.address, executor.address)

    const deployerRole = await factory.DEPLOYER_ROLE()
    await factory.connect(owner).grantRole(deployerRole, multiCall.address)

    const Token = await ethers.getContractFactory('ERC20Mock')

    const token = await Token.connect(owner).deploy()

    return {
      owner,
      executor,
      acc1,
      factory,
      mainModule,
      multiCall,
      networkId,
      optimalGasLimit,
      token
    }
  }

  describe('deployAndExecute', function () {
    it('Should deploy and execute transfers', async function () {
      const owner_a = new ethers.Wallet(ethers.utils.randomBytes(32))
      const salt = encodeImageHash(1, [{ weight: 1, address: owner_a.address }])
      const { factory, mainModule, multiCall, executor, acc1, owner, networkId, optimalGasLimit, token } = await loadFixture(
        setupFactoryFixture
      )

      // CFA
      const cfa = addressOf(factory.address, mainModule.address, salt)

      // Transfer tokens to CFA
      await token.connect(owner).transfer(cfa, ethers.utils.parseEther('5'))
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('5'))

      // We don't want delegate call here as the state is contained to the ERC20 contract
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: optimalGasLimit,
        target: token.address,
        value: ethers.constants.Zero,
        data: token.interface.encodeFunctionData('transfer', [acc1.address, ethers.utils.parseEther('2.5')])
      }

      // Signing
      const data = encodeMetaTransactionsData(cfa, [transaction], networkId, ethers.constants.Zero)
      const sig = walletMultiSign([{ weight: 1, owner: owner_a }], 1, data, false)

      // Execution
      await multiCall.connect(executor).deployAndExecute(cfa, mainModule.address, salt, factory.address, [transaction], 0, sig)
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('2.5'))

      // Transfer remaining, resign Tx with incremented nonce
      // Here the deployment will be skipped and the transaction will be executed
      const dataTwo = encodeMetaTransactionsData(cfa, [transaction], networkId, 1)
      const sigTwo = walletMultiSign([{ weight: 1, owner: owner_a }], 1, dataTwo, false)
      await multiCall.connect(executor).deployAndExecute(cfa, mainModule.address, salt, factory.address, [transaction], 1, sigTwo)
      expect(await token.balanceOf(cfa)).to.equal(0)
    })

    it('Should fail with a CFA mismatch', async function () {
      const owner_b = new ethers.Wallet(ethers.utils.randomBytes(32))
      const salt = encodeImageHash(1, [{ weight: 1, address: owner_b.address }])
      const { factory, mainModule, multiCall, acc1, executor, owner, networkId, optimalGasLimit } = await loadFixture(setupFactoryFixture)

      // CFA
      const cfa = addressOf(factory.address, mainModule.address, salt)

      // Mint tokens
      const Token = await ethers.getContractFactory('ERC20Mock')
      const token = await Token.connect(owner).deploy()

      // Transfer tokens to CFA
      await token.connect(owner).transfer(cfa, ethers.utils.parseEther('5'))
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('5'))

      // We don't want delegate call here as the state is contained to the ERC20 contract
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: optimalGasLimit,
        target: token.address,
        value: ethers.constants.Zero,
        data: token.interface.encodeFunctionData('transfer', [acc1.address, ethers.utils.parseEther('2.5')])
      }

      // Signing
      const data = encodeMetaTransactionsData(cfa, [transaction], networkId, ethers.constants.Zero)
      const sig = walletMultiSign([{ weight: 1, owner: owner_b }], 1, data, false)

      // Execution
      await expect(
        multiCall
          .connect(executor)
          .deployAndExecute(owner_b.address, mainModule.address, salt, factory.address, [transaction], 0, sig)
      ).to.be.revertedWith('MultiCallDeploy: deployed address does not match CFA')
    })
  })

  describe('deployExecute', function () {
    it('Should deploy and and execute transfer', async function () {
      const owner_c = new ethers.Wallet(ethers.utils.randomBytes(32))
      const salt = encodeImageHash(1, [{ weight: 1, address: owner_c.address }])
      const { factory, mainModule, multiCall, acc1, executor, owner, networkId, optimalGasLimit, token } = await loadFixture(
        setupFactoryFixture
      )

      // CFA
      const cfa = addressOf(factory.address, mainModule.address, salt)

      // Transfer tokens to CFA
      await token.connect(owner).transfer(cfa, ethers.utils.parseEther('5'))
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('5'))

      // We don't want delegate call here as the state is contained to the ERC20 contract
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: optimalGasLimit,
        target: token.address,
        value: ethers.constants.Zero,
        data: token.interface.encodeFunctionData('transfer', [acc1.address, ethers.utils.parseEther('2.5')])
      }

      // Signing
      const data = encodeMetaTransactionsData(cfa, [transaction], networkId, ethers.constants.Zero)
      const sig = walletMultiSign([{ weight: 1, owner: owner_c }], 1, data, false)

      // Execution
      await multiCall.connect(executor).deployExecute(mainModule.address, salt, factory.address, [transaction], 0, sig)
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('2.5'))
    })

    it('Should fail if the wallet is already deployed', async function () {
      const owner_d = new ethers.Wallet(ethers.utils.randomBytes(32))
      const salt = encodeImageHash(1, [{ weight: 1, address: owner_d.address }])
      const { factory, mainModule, multiCall, acc1, executor, owner, networkId, optimalGasLimit, token } = await loadFixture(
        setupFactoryFixture
      )

      // CFA
      const cfa = addressOf(factory.address, mainModule.address, salt)

      // Transfer tokens to CFA
      await token.connect(owner).transfer(cfa, ethers.utils.parseEther('5'))
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('5'))

      // We don't want delegate call here as the state is contained to the ERC20 contract
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: optimalGasLimit,
        target: token.address,
        value: ethers.constants.Zero,
        data: token.interface.encodeFunctionData('transfer', [acc1.address, ethers.utils.parseEther('2.5')])
      }

      // Signing
      const data = encodeMetaTransactionsData(cfa, [transaction], networkId, ethers.constants.Zero)
      const sig = walletMultiSign([{ weight: 1, owner: owner_d }], 1, data, false)

      // Execution
      await multiCall.connect(executor).deployExecute(mainModule.address, salt, factory.address, [transaction], 0, sig)

      // Repeat above process, re-triggering deployment
      const dataTwo = encodeMetaTransactionsData(cfa, [transaction], networkId, 1)
      const sigTwo = walletMultiSign([{ weight: 1, owner: owner_d }], 1, dataTwo, false)

      // Attempt to re-deploy
      await expect(
        multiCall.connect(executor).deployExecute(mainModule.address, salt, factory.address, [transaction], 0, sigTwo)
      ).to.be.revertedWith('WalletFactory: deployment failed')
    })

    it('Should fail if the submitter does not have the executor role', async function () {
      const owner_d = new ethers.Wallet(ethers.utils.randomBytes(32))
      const salt = encodeImageHash(1, [{ weight: 1, address: owner_d.address }])
      const { factory, mainModule, multiCall, acc1, executor, owner, networkId, optimalGasLimit, token } = await loadFixture(
        setupFactoryFixture
      )

      // CFA
      const cfa = addressOf(factory.address, mainModule.address, salt)

      // Transfer tokens to CFA
      await token.connect(owner).transfer(cfa, ethers.utils.parseEther('5'))
      expect(await token.balanceOf(cfa)).to.equal(ethers.utils.parseEther('5'))

      // We don't want delegate call here as the state is contained to the ERC20 contract
      const transaction = {
        delegateCall: false,
        revertOnError: true,
        gasLimit: optimalGasLimit,
        target: token.address,
        value: ethers.constants.Zero,
        data: token.interface.encodeFunctionData('transfer', [acc1.address, ethers.utils.parseEther('2.5')])
      }

      // Signing
      const data = encodeMetaTransactionsData(cfa, [transaction], networkId, ethers.constants.Zero)
      const sig = walletMultiSign([{ weight: 1, owner: owner_d }], 1, data, false)

      // Execution
      await expect(multiCall.connect(acc1).deployExecute(mainModule.address, salt, factory.address, [transaction], 0, sig)).to.be.revertedWith("AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63")
      await expect(multiCall.connect(acc1).deployAndExecute(cfa, mainModule.address, salt, factory.address, [transaction], 0, sig)).to.be.revertedWith("AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63")
    })
  })
})