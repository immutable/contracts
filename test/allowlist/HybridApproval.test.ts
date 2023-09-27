import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ImmutableERC721,
  MockMarketplace,
  MockFactory,
  OperatorAllowlist,
  MockOnReceive,
  MockOnReceive__factory,
  MockWalletFactory,
} from "../../typechain";
import { AllowlistFixture, walletSCFixture, disguidedEOAFixture } from "../utils/DeployHybridFixtures";

describe("Royalty Checks with Hybrid ERC721", function () {
  let erc721: ImmutableERC721;
  let walletFactory: MockWalletFactory;
  let factory: MockFactory;
  let operatorAllowlist: OperatorAllowlist;
  let marketPlace: MockMarketplace;
  let deployedAddr: string; // deployed SC wallet address
  let moduleAddress: string;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let scWallet: SignerWithAddress;
  let accs: SignerWithAddress[];

  beforeEach(async function () {
    [owner, minter, registrar, scWallet, ...accs] = await ethers.getSigners();

    // Get all required contracts
    ({ erc721, walletFactory, factory, operatorAllowlist, marketPlace } = await AllowlistFixture(owner));
    // Deploy the wallet fixture
    ({ deployedAddr, moduleAddress } = await walletSCFixture(scWallet, walletFactory));

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await operatorAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Operator Allowlist Registry setting", function () {
    it("Should have operatorAllowlist set upon deployment", async function () {
      expect(await erc721.operatorAllowlist()).to.equal(operatorAllowlist.address);
    });

    it("Should not allow contracts that do not implement the IOperatorAllowlist to be set", async function () {
      // Deploy another contract that implements IERC165, but not IOperatorAllowlist
      const factory = await ethers.getContractFactory("ImmutableERC721");
      const erc721Two = await factory.deploy(
        owner.address,
        "",
        "",
        "",
        "",
        operatorAllowlist.address,
        owner.address,
        0
      );

      await expect(erc721.connect(owner).setOperatorAllowlistRegistry(erc721Two.address)).to.be.revertedWith(
        "AllowlistDoesNotImplementIOperatorAllowlist"
      );
    });

    it("Should not allow a non-admin to access the function to update the registry", async function () {
      await expect(
        erc721.connect(registrar).setOperatorAllowlistRegistry(operatorAllowlist.address)
      ).to.be.revertedWith(
        "AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });

  describe("Approvals", function () {
    it("Should not allow a non-Allowlisted operator to be approved", async function () {
      await erc721.connect(minter).mint(minter.address, 1);
      // Approve for all
      await expect(erc721.connect(minter).approve(marketPlace.address, 1))
        .to.be.revertedWith("ApproveTargetNotInAllowlist")
        .withArgs(marketPlace.address);
      // Approve
      await expect(erc721.connect(minter).approve(marketPlace.address, 1))
        .to.be.revertedWith("ApproveTargetNotInAllowlist")
        .withArgs(marketPlace.address);
    });

    it("Should allow EOAs to be approved", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      await erc721.connect(minter).mintByQuantity(minter.address, 1);
      // Approve EOA addr
      const tokenId = first;
      await erc721.connect(minter).approve(accs[0].address, tokenId);
      await erc721.connect(minter).setApprovalForAll(accs[0].address, true);
      expect(await erc721.getApproved(tokenId)).to.be.equal(accs[0].address);
      expect(await erc721.isApprovedForAll(minter.address, accs[0].address)).to.be.equal(true);
    });

    it("Should allow Allowlisted addresses to be approved", async function () {
      // Add the mock marketplace to registry
      await operatorAllowlist.connect(registrar).addAddressToAllowlist([marketPlace.address]);
      const first = await erc721.mintBatchByQuantityThreshold();
      await erc721.connect(minter).mintByQuantity(minter.address, 1);
      const tokenId = first;
      // Approve marketplace on erc721 contract
      await erc721.connect(minter).approve(marketPlace.address, tokenId);
      await erc721.connect(minter).setApprovalForAll(marketPlace.address, true);
      expect(await erc721.getApproved(tokenId)).to.be.equal(marketPlace.address);
      expect(await erc721.isApprovedForAll(minter.address, marketPlace.address)).to.be.equal(true);
    });

    it("Should allow Allowlisted smart contract wallets to be approved", async function () {
      // Allowlist the bytecode
      await operatorAllowlist.connect(registrar).addWalletToAllowlist(deployedAddr);
      const first = await erc721.mintBatchByQuantityThreshold();
      await erc721.connect(minter).mintByQuantity(minter.address, 1);
      const tokenId = first;
      await erc721.connect(minter).approve(deployedAddr, tokenId);
      // Approve the smart contract wallet
      await erc721.connect(minter).setApprovalForAll(deployedAddr, true);
      expect(await erc721.getApproved(tokenId)).to.be.equal(deployedAddr);
      expect(await erc721.isApprovedForAll(minter.address, deployedAddr)).to.be.equal(true);
    });
  });

  describe("Transfers", function () {
    beforeEach(async function () {
      await erc721.connect(owner).setOperatorAllowlistRegistry(operatorAllowlist.address);
    });
    it("Should freely allow transfers between EOAs", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      await erc721.connect(minter).mintByQuantity(accs[0].address, 1);
      await erc721.connect(minter).mintByQuantity(accs[1].address, 1);
      const tokenIdOne = first;
      const tokenIdTwo = first.add(1);

      // Transfer
      await erc721.connect(accs[0]).transferFrom(accs[0].address, accs[2].address, tokenIdOne);
      await erc721.connect(accs[1]).transferFrom(accs[1].address, accs[2].address, tokenIdTwo);
      // Check balance
      expect(await erc721.balanceOf(accs[2].address)).to.be.equal(2);
      // Transfer again
      await erc721.connect(accs[2]).transferFrom(accs[2].address, accs[0].address, tokenIdOne);
      await erc721.connect(accs[2]).transferFrom(accs[2].address, accs[1].address, tokenIdTwo);
      // Check final balance
      expect(await erc721.balanceOf(accs[2].address)).to.be.equal(0);

      // Approved EOA account should be able to transfer
      await erc721.connect(accs[0]).setApprovalForAll(accs[2].address, true);
      await erc721.connect(accs[2]).transferFrom(accs[0].address, accs[2].address, tokenIdOne);
      expect(await erc721.balanceOf(accs[2].address)).to.be.equal(1);
    });

    it("Should block transfers from a not allow listed contracts", async function () {
      const first = await erc721.mintBatchByQuantityThreshold();
      await erc721.connect(minter).mintByQuantity(marketPlace.address, 1);
      const tokenId = first;
      await expect(marketPlace.connect(minter).executeTransferFrom(marketPlace.address, minter.address, tokenId))
        .to.be.revertedWith("CallerNotInAllowlist")
        .withArgs(marketPlace.address);
    });

    it("Should block transfers to a not allow listed address", async function () {
      await erc721.connect(minter).mint(minter.address, 1);
      await expect(erc721.connect(minter).transferFrom(minter.address, marketPlace.address, 1))
        .to.be.revertedWith("TransferToNotInAllowlist")
        .withArgs(marketPlace.address);
    });

    it("Should not block transfers from an allow listed contract", async function () {
      await operatorAllowlist.connect(registrar).addAddressToAllowlist([marketPlace.address]);
      await erc721.connect(minter).mint(minter.address, 4);
      await erc721.connect(minter).setApprovalForAll(marketPlace.address, true);
      expect(await erc721.balanceOf(accs[3].address)).to.be.equal(0);
      await marketPlace.connect(minter).executeTransfer(accs[3].address, 4);
      expect(await erc721.balanceOf(accs[3].address)).to.be.equal(1);
    });

    it("Should not block transfers between allow listed smart contract wallets", async function () {
      // Deploy more SC wallets
      const salt = ethers.utils.keccak256("0x4567");
      const saltTwo = ethers.utils.keccak256("0x5678");
      const saltThree = ethers.utils.keccak256("0x6789");
      await walletFactory.connect(scWallet).deploy(moduleAddress, salt);
      await walletFactory.connect(scWallet).deploy(moduleAddress, saltTwo);
      await walletFactory.connect(scWallet).deploy(moduleAddress, saltThree);
      const deployedAddr = await walletFactory.getAddress(moduleAddress, salt);

      await operatorAllowlist.connect(registrar).addWalletToAllowlist(deployedAddr);

      const deployedAddrTwo = await walletFactory.getAddress(moduleAddress, saltTwo);
      const deployedAddrThree = await walletFactory.getAddress(moduleAddress, saltThree);
      // Mint NFTs to the wallets
      await erc721.connect(minter).mint(deployedAddr, 10);
      await erc721.connect(minter).mint(deployedAddrTwo, 11);

      // Connect to wallets
      const wallet = await ethers.getContractAt("MockWallet", deployedAddr);
      const walletTwo = await ethers.getContractAt("MockWallet", deployedAddrTwo);
      const walletThree = await ethers.getContractAt("MockWallet", deployedAddrThree);

      // Transfer between wallets
      await wallet.transferNFT(erc721.address, deployedAddr, deployedAddrThree, 10);
      await walletTwo.transferNFT(erc721.address, deployedAddrTwo, deployedAddrThree, 11);
      expect(await erc721.balanceOf(deployedAddr)).to.be.equal(0);
      expect(await erc721.balanceOf(deployedAddrTwo)).to.be.equal(0);
      expect(await erc721.balanceOf(deployedAddrThree)).to.be.equal(2);
      await walletThree.transferNFT(erc721.address, deployedAddrThree, deployedAddr, 10);
      await walletThree.transferNFT(erc721.address, deployedAddrThree, deployedAddrTwo, 11);
      expect(await erc721.balanceOf(deployedAddr)).to.be.equal(1);
      expect(await erc721.balanceOf(deployedAddrTwo)).to.be.equal(1);
      expect(await erc721.balanceOf(deployedAddrThree)).to.be.equal(0);
    });
  });

  describe("Malicious Contracts", function () {
    beforeEach(async function () {
      await erc721.connect(owner).setOperatorAllowlistRegistry(operatorAllowlist.address);
    });
    // The EOA disguise attack vector is a where a pre-computed CREATE2 deterministic address is disguised as an EOA.
    // By virtue of this, approvals and transfers to this address will pass. We need to catch actions from this address
    // once it is deployed.
    it("EOA disguise approve", async function () {
      // This attack vector is where a CFA is approved prior to deployment. This passes as at the time of approval as
      // the CFA is treated as an EOA, passing _validateApproval.
      // This means post-deployment that the address is now an approved operator
      // and is able to call transferFrom.
      const { deployedAddr, salt, constructorByteCode } = await disguidedEOAFixture(erc721.address, factory, "0x1234");
      // Approve disguised EOA
      await erc721.connect(minter).mint(minter.address, 1);
      await erc721.connect(minter).setApprovalForAll(deployedAddr, true);
      // Deploy disguised EOA
      await factory.connect(accs[5]).deploy(salt, constructorByteCode);
      expect(await erc721.isApprovedForAll(minter.address, deployedAddr)).to.be.equal(true);
      // Attempt to execute a transferFrom, w/ msg.sender being the disguised EOA
      const disguisedEOAFactory = ethers.getContractFactory("MockDisguisedEOA");
      const disguisedEOA = (await disguisedEOAFactory).attach(deployedAddr);
      // Catch transfer as msg.sender != tx.origin
      await expect(disguisedEOA.connect(minter).executeTransfer(minter.address, accs[5].address, 1))
        .to.be.revertedWith("CallerNotInAllowlist")
        .withArgs(deployedAddr);
    });

    it("EOA disguise transferFrom", async function () {
      // This vector is where the NFT is transferred to the CFA and executes a transferFrom inside its constructor.
      // TODO: investigate why transferFrom calls fail within the constructor. This will be caught as msg.sender != tx.origin.
    });

    // Here the malicious contract attempts to transfer the token out of the contract by calling transferFrom in onERC721Received
    // However, sending to the contract will fail as the contract is not in the allowlist.
    it("onRecieve transferFrom", async function () {
      // Deploy contract
      const mockOnReceiveFactory = (await ethers.getContractFactory("MockOnReceive")) as MockOnReceive__factory;
      const onRecieve: MockOnReceive = await mockOnReceiveFactory.deploy(erc721.address, accs[6].address);
      // Mint and transfer to receiver contract
      await erc721.connect(minter).mint(minter.address, 1);
      // Fails as transfer 'to' is now allowlisted
      await expect(
        erc721.connect(minter)["safeTransferFrom(address,address,uint256)"](minter.address, onRecieve.address, 1)
      )
        .to.be.revertedWith("TransferToNotInAllowlist")
        .withArgs(onRecieve.address);
    });
  });
});
