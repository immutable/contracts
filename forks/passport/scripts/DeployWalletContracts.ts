import * as path from 'path'
import * as fs from 'fs'
import * as hre from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { ethers } from 'ethers'
import { ethers as hardhat } from 'hardhat'
import { expect } from 'chai'

require('dotenv').config()

const outputPath = path.join(__dirname, './deploy_output.json')
let deployer: SignerWithAddress

async function deploy() {
  // TODO: We should obtain an API key for blockscout and uncomment
  // the following lines before a mainnet deployment
  // if (typeof process.env.ETHERSCAN_API_KEY === 'undefined') {
  //     throw new Error('Etherscan API KEY has not been defined');
  // }

  // /dev/imx-evm-relayer/EOA_SUBMITTER
  let relayerSubmitterEOAPubKey = '0xBC52cE84FceFd2D941D1127608D6Cf598f9633d3'
  // /dev/imx-evm-relayer/IMMUTABLE_SIGNER_CONTRACT
  let immutableSignerPubKey = '0x1cE50560686b1297B6311F36B47dbe5d6E04D0f8'
  // Administration accounts
  let multiCallAdminPubKey = '0x575be326c482a487add43974e0eaf232e3366e13'
  let factoryAdminPubKey = '0xddb70ddcd14dbd57ae18ec591f47454e4fc818bb'
  let walletImplLocatorAdmin = '0xb49c99a17776c10350c2be790e13d4d8dfb1c578'
  let signerRootAdminPubKey = '0x65af83f71a05d7f6d06ef9a57c9294b4128ccc2c'
  let signerAdminPubKey = '0x69d09644159e7327dbfd0af9a66f8e332c593e79'

  // Required private keys:
  // 1. Deployer
  // 2. walletImplLocatorChanger
  const [contractDeployer, walletImplLocatorImplChanger] = await hardhat.getSigners()
  deployer = contractDeployer

  // TOTAL deployment cost = 0.009766773 GWEI = 0.000000000009766773 ETHER
  // Deployments with esimated gas costs (GWEI)
  console.log('Deploying contracts...')
  // 1. Deploy multi call deploy
  // EST gas cost: 0.001561956
  const multiCallDeploy = await deployMultiCallDeploy(multiCallAdminPubKey, relayerSubmitterEOAPubKey)
  await multiCallDeploy.deployTransaction.wait()
  console.log('Multi Call Deploy deployed to: ', multiCallDeploy.address)

  // 2. Deploy factory with multi call deploy address as deployer role EST
  // EST gas cost: 0.001239658
  const factory = await deployFactory(factoryAdminPubKey, multiCallDeploy.address)
  await factory.deployTransaction.wait()
  console.log(`Factory deployed to: ${factory.address} with hash ${factory.deployTransaction.hash}`)

  // 3. Deploy wallet impl locator
  // EST gas cost: 0.001021586
  const walletImplLocator = await deployWalletImplLocator(walletImplLocatorAdmin, walletImplLocatorImplChanger.address)
  await walletImplLocator.deployTransaction.wait()
  console.log(
    `Wallet Implementation Locator deployed to: ${walletImplLocator.address} with hash ${walletImplLocator.deployTransaction.hash}`
  )

  // 4. Deploy startup wallet impl
  // EST gas cost: 0.000175659
  const startupWalletImpl = await deployStartUp(walletImplLocator.address)
  await startupWalletImpl.deployTransaction.wait()
  console.log(
    `Startup Wallet Impl deployed to: ${startupWalletImpl.address} with hash ${startupWalletImpl.deployTransaction.hash}`
  )

  // 5. Deploy main module dynamic auth
  // EST gas cost: 0.003911813
  const mainModule = await deployMainModule(factory.address, startupWalletImpl.address)
  await mainModule.deployTransaction.wait()
  console.log(`Main Module Dynamic Auth deployed to: ${mainModule.address} with hash ${mainModule.deployTransaction.hash}`)

  // 6. Deploy immutable signer
  // EST gas cost: 0.001856101
  const immutableSigner = await deployImmutableSigner(signerRootAdminPubKey, signerAdminPubKey, immutableSignerPubKey)
  await immutableSigner.deployTransaction.wait()
  console.log('Finished deploying contracts')

  // Fund the implementation changer
  // WARNING: If the deployment fails at this step, DO NOT RERUN without commenting out the code a prior which deploys
  // the contracts.
  // TODO: Code below can be improved by calculating the amount that is required to be transferred.
  const fundingTx = await deployer.sendTransaction({
    to: await walletImplLocatorImplChanger.getAddress(),
    value: ethers.utils.parseEther('10')
  })
  await fundingTx.wait()

  console.log(`Transfered funds to the wallet locator implementer changer with hash ${fundingTx.hash}`)

  // Set implementation address on impl locator to dyanmic module auth addr
  const tx = await walletImplLocator.connect(walletImplLocatorImplChanger).changeWalletImplementation(mainModule.address)
  await tx.wait()
  console.log('Wallet Implentation Locator implementation changed to: ', mainModule.address)

  // Output JSON file with addresses and role addresses
  const JSONOutput = {
    FactoryAddress: factory.address,
    WalletImplLocatorAddress: walletImplLocator.address,
    StartupWalletImplAddress: startupWalletImpl.address,
    MainModuleDynamicAuthAddress: mainModule.address,
    ImmutableSignerContractAddress: immutableSigner.address,
    MultiCallDeployAddress: multiCallDeploy.address,
    DeployerAddress: deployer.address,
    FactoryAdminAddress: factoryAdminPubKey,
    FactoryDeployerAddress: relayerSubmitterEOAPubKey,
    WalletImplLocatorAdminAddress: walletImplLocatorAdmin,
    WalletImplLocatorImplChangerAddress: walletImplLocatorImplChanger.address,
    SignerRootAdminAddress: signerRootAdminPubKey,
    SignerAdminAddress: signerAdminPubKey,
    ImmutableSignerAddress: immutableSignerPubKey,
    MultiCallAdminAddress: multiCallAdminPubKey,
    MultiCallExecutorAddress: relayerSubmitterEOAPubKey
  }
  fs.writeFileSync(outputPath, JSON.stringify(JSONOutput, null, 1))

  // Verify contracts on etherscan
  // console.log("Verifying contracts on etherscan...");
  // await verifyContract(multiCallDeploy.address, [multiCallAdminPubKey, relayerSubmitterEOAPubKey]);
  // await verifyContract(factory.address,  [factoryAdminPubKey, multiCallDeploy.address]);
  // await verifyContract(walletImplLocator.address, [walletImplLocatorAdmin, walletImplLocatorImplChanger.address]);
  // await verifyContract(startupWalletImpl.address, [walletImplLocator.address]);
  // await verifyContract(mainModule.address, [factory.address, startupWalletImpl.address], true, "contracts/modules/MainModuleDynamicAuth.sol:MainModuleDynamicAuth");
  // await verifyContract(immutableSigner.address, [signerRootAdminPubKey, signerAdminPubKey, relayerSubmitterEOAPubKey]);
  console.log('Skipping contract verification... (Etherscan not available on Immutable zkEVM)')
}

async function deployFactory(adminAddr: string, deployerAddr: string): Promise<ethers.Contract> {
  const Factory = await hardhat.getContractFactory('Factory')
  return await Factory.connect(deployer).deploy(adminAddr, deployerAddr)
}

async function deployWalletImplLocator(adminAddr: string, implChangerAddr: string): Promise<ethers.Contract> {
  const LatestWalletImplLocator = await hardhat.getContractFactory('LatestWalletImplLocator')
  return await LatestWalletImplLocator.connect(deployer).deploy(adminAddr, implChangerAddr)
}

async function deployStartUp(walletImplLocatorAddr: string): Promise<ethers.Contract> {
  const StartupWalletImplImpl = await hardhat.getContractFactory('StartupWalletImpl')
  return await StartupWalletImplImpl.connect(deployer).deploy(walletImplLocatorAddr)
}

async function deployMainModule(factoryAddr: string, startUpAddr: string): Promise<ethers.Contract> {
  const MainModuleDynamicAuth = await hardhat.getContractFactory('MainModuleDynamicAuth')
  return await MainModuleDynamicAuth.connect(deployer).deploy(factoryAddr, startUpAddr)
}

async function deployImmutableSigner(
  rootAdminAddr: string,
  signerAdminAddr: string,
  signerAddr: string
): Promise<ethers.Contract> {
  const ImmutableSigner = await hardhat.getContractFactory('ImmutableSigner')
  return await ImmutableSigner.connect(deployer).deploy(rootAdminAddr, signerAdminAddr, signerAddr)
}

async function deployMultiCallDeploy(adminAddr: string, executorAddr: string): Promise<ethers.Contract> {
  const MultiCallDeploy = await hardhat.getContractFactory('MultiCallDeploy')
  return await MultiCallDeploy.connect(deployer).deploy(adminAddr, executorAddr, {})
}

async function verifyContract(
  contractAddr: string,
  constructorArgs: any[],
  requiesContractPath: boolean = false,
  contractPath: string = ''
) {
  try {
    if (requiesContractPath) {
      await hre.run('verify:verify', {
        contract: contractPath,
        address: contractAddr,
        constructorArguments: constructorArgs
      })
    } else {
      await hre.run('verify:verify', {
        address: contractAddr,
        constructorArguments: constructorArgs
      })
    }
  } catch (error) {
    expect(error.message.toLowerCase().includes('already verified')).to.be.equal(true)
  }
}

deploy().catch(error => {
  console.error(error)
  process.exitCode = 1
})
