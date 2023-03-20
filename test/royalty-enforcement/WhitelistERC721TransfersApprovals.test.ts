import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ImmutableERC721PermissionedMintable,
  MockMarketplace,
  MockFactory,
  RoyaltyWhitelist,
  MockOnReceive,
  MockOnReceive__factory,
} from "../../typechain";
import {
  whitelistFixture,
  walletSCFixture,
  disguidedEOAFixture,
} from "../utils/DeployFixtures";

describe("Whitelisted ERC721 Transfers", function () {
  this.timeout(300_000); // 5 min

  let erc721: ImmutableERC721PermissionedMintable;
  let MockFactory: MockFactory;
  let royaltyWhitelist: RoyaltyWhitelist;
  let mockMarketPlace: MockMarketplace;
  let deployedSCWalletAddr: string;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let scWallet: SignerWithAddress;
  let accs: SignerWithAddress[];

  before(async function () {
    [owner, minter, registrar, scWallet, ...accs] =
      await ethers.getSigners();

    // Get all required contracts
    ({ erc721, MockFactory, royaltyWhitelist, mockMarketPlace } =
      await whitelistFixture(owner));

    // Deploy SC wallet
    deployedSCWalletAddr = await walletSCFixture(
      scWallet,
      erc721.address,
      MockFactory
    );

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await royaltyWhitelist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Royalty Whitelist Registry setting", function () {
    it("Should set the whitelist registry to a contract the implements the IRoyaltyWhitelist interface", async function () {
      await expect(erc721
        .connect(owner)
        .setRoyaltyWhitelistRegistry(royaltyWhitelist.address)).to.emit(erc721, "RoyaltytWhitelistRegistryUpdated")
        .withArgs(ethers.constants.AddressZero, royaltyWhitelist.address);

      expect(await erc721.royaltyWhitelist()).to.equal(
        royaltyWhitelist.address
      );
    });

    it("Should not allow non-contract accounts to be set as whitelist registry", async function () {
      // These should fail on the IERC165.supportsInterface call
      // Zero address
      await expect(
        erc721
          .connect(owner)
          .setRoyaltyWhitelistRegistry(ethers.constants.AddressZero)
      ).to.be.revertedWith("function call to a non-contract account");

      // EOA address
      await expect(
        erc721.connect(owner).setRoyaltyWhitelistRegistry(owner.address)
      ).to.be.revertedWith("function call to a non-contract account");
    });

    it("Should not allow contracts that do not implement the IRoyaltyWhitelist to be set", async function () {
      // Deploy another contract that implements IERC165, but not IRoyaltyWhitelist
      let erc721Two;
      const factory = await ethers.getContractFactory(
        "ImmutableERC721PermissionedMintable"
      );
      erc721Two = await factory.deploy(
        owner.address,
        "",
        "",
        "",
        "",
        owner.address,
        0
      );

      await expect(
        erc721.connect(owner).setRoyaltyWhitelistRegistry(erc721Two.address)
      ).to.be.revertedWith("contract does not implement IRoyaltyWhitelist");
    });

    it("Should not allow a non-admin to access the function to update the registry", async function () {
      await expect(
        erc721
          .connect(registrar)
          .setRoyaltyWhitelistRegistry(royaltyWhitelist.address)
      ).to.be.revertedWith(
        "AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });

  describe("Approvals", function () {
    it("Should not allow a non-whitelisted operator to be approved", async function () {
      // Approve for all
      await expect(
        erc721.connect(minter).setApprovalForAll(mockMarketPlace.address, true)
      ).to.be.revertedWith(
        `'ApproveTargetNotInWhitelist("${mockMarketPlace.address}")'`
      );
      // Approve
      await expect(
        erc721.connect(minter).approve(mockMarketPlace.address, 1)
      ).to.be.revertedWith(
        `'ApproveTargetNotInWhitelist("${mockMarketPlace.address}")'`
      );
    });

    it("Should allow EOAs to be approved", async function () {
      await erc721.connect(minter).mint(minter.address, 3);
      // Approve EOA addr
      await erc721.connect(minter).approve(accs[0].address, 1);
      await erc721.connect(minter).setApprovalForAll(accs[0].address, true);
      expect(await erc721.getApproved(1)).to.be.equal(accs[0].address);
      expect(await erc721.isApprovedForAll(minter.address, accs[0].address)).to
        .be.true;
    });

    it("Should allow whitelisted addresses to be approved", async function () {
      // Add the mock marketplace to registry
      await royaltyWhitelist
        .connect(registrar)
        .addAddressToWhitelist(mockMarketPlace.address);
      // Approve marketplace on erc721 contract
      await erc721.connect(minter).approve(mockMarketPlace.address, 2);
      await erc721
        .connect(minter)
        .setApprovalForAll(mockMarketPlace.address, true);
      expect(await erc721.getApproved(2)).to.be.equal(mockMarketPlace.address);
      expect(
        await erc721.isApprovedForAll(minter.address, mockMarketPlace.address)
      ).to.be.true;
    });

    it("Should allow whitelisted bytecode to be approved", async function () {
      // Get bytecode at deployed SC wallet address
      const deployedBytecode = await ethers.provider.getCode(
        deployedSCWalletAddr
      );
      // Whitelist the bytecode
      await royaltyWhitelist
        .connect(registrar)
        .addBytecodeToWhitelist(ethers.utils.keccak256(deployedBytecode));
      await erc721.connect(minter).approve(deployedSCWalletAddr, 3);
      // Approve the address w/ implements approved bytecode
      await erc721
        .connect(minter)
        .setApprovalForAll(deployedSCWalletAddr, true);
      expect(await erc721.getApproved(3)).to.be.equal(deployedSCWalletAddr);
      expect(
        await erc721.isApprovedForAll(minter.address, deployedSCWalletAddr)
      ).to.be.true;
    });
  });

  describe("Transfers", function () {
    it("Should freely allow transfers between EOAs", async function () {
      await erc721.connect(owner).grantMinterRole(accs[0].address);
      await erc721.connect(owner).grantMinterRole(accs[1].address);
      await erc721.connect(accs[0]).mint(accs[0].address, 1);
      await erc721.connect(accs[1]).mint(accs[1].address, 1);
      // Transfer 
      await erc721
        .connect(accs[0])
        .transferFrom(accs[0].address, accs[2].address, 4);
      await erc721
        .connect(accs[1])
        .transferFrom(accs[1].address, accs[2].address, 5);
      // Check balance
      expect(await erc721.balanceOf(accs[2].address)).to.be.equal(2);
      // Transfer again
      await erc721
        .connect(accs[2])
        .transferFrom(accs[2].address, accs[0].address, 4);
      await erc721
        .connect(accs[2])
        .transferFrom(accs[2].address, accs[1].address, 5);
      // Check final balance
      expect(await erc721.balanceOf(accs[2].address)).to.be.equal(0);
    });

    it("Should not block transfers from a whitelisted contract", async function () {
      // mock marketplace has already been approved
      expect(await erc721.balanceOf(accs[3].address)).to.be.equal(0);
      await mockMarketPlace.connect(minter).executeTransfer(accs[3].address, 2);
      expect(await erc721.balanceOf(accs[3].address)).to.be.equal(1);
    });

    it("Should not block transfers from a contract w/ whitelisted bytecode", async function () {
      // Mint an NFT to SC wallet
      await erc721.connect(minter).mint(deployedSCWalletAddr, 1);
      // Get code at deployed addr
      const walletMockFactory = ethers.getContractFactory("MockWallet");
      const wallet = (await walletMockFactory).attach(deployedSCWalletAddr);
      // Mint NFT to SC wallet addr
      expect(await erc721.balanceOf(accs[4].address)).to.be.equal(0);
      await wallet.connect(scWallet).transferNFT(accs[4].address, 6);
       // Transfer NFT from SC wallet
      expect(await erc721.balanceOf(accs[4].address)).to.be.equal(1);
    });
  });

  describe("Malicious Contracts", function () {
    // The EOA disguise vector is a where a pre-computed CREATE2 deterministic address is disguised as an EOA.
    // By virtue of this, approvals and transfers to this address will pass. We need to catch actions from this address
    // once it is deployed.
    it("EOA disguise approve", async function () {
      // This vector is where a CFA is approved prior to deployment. This passes as at the time of approval as
      // the CFA is treated as an EOA, passing _validateApproval.
      // This means post-deployment that the address is now an approved operator
      // and is able to call transferFrom.
      let deployedAddr;
      let salt;
      let constructorByteCode;

      ({ deployedAddr, salt, constructorByteCode } = await disguidedEOAFixture(
        erc721.address,
        MockFactory,
        "0x1234"
      ));
      // Approve disguised EOA
      await erc721.connect(minter).mint(minter.address, 1);
      await erc721.connect(minter).setApprovalForAll(deployedAddr, true);
      // Deploy disguised EOA
      await MockFactory.connect(accs[5]).deploy(salt, constructorByteCode);
      expect(
        await erc721.isApprovedForAll(minter.address, deployedAddr)
      ).to.be.equal(true);
      // Attempt to execute a transferFrom, w/ msg.sender being the disguised EOA
      const disguisedEOAFactory = ethers.getContractFactory("MockDisguisedEOA");
      const disguisedEOA = (await disguisedEOAFactory).attach(deployedAddr);
      // Catch transfer as msg.sender != tx.origin
      await expect(
        disguisedEOA
          .connect(minter)
          .executeTransfer(minter.address, accs[5].address, 7)
      ).to.be.revertedWith(`'CallerNotInWhitelist("${deployedAddr}")'`);
    });

    it("EOA disguise transferFrom", async function () {
     // This vector is where the NFT is transferred to the CFA and executes a transferFrom inside its constructor.
     // TODO: investigate why transferFrom calls fail within the constructor. This will be caught as msg.sender != tx.origin.
    });
    
    // Here the malicious contract attempts to transfer the token out of the contract by calling transferFrom in onERC721Received
    it("onRecieve transferFrom", async function () {
      // Deploy contract
      let onRecieve: MockOnReceive;
      const mockOnReceiveFactory = (await ethers.getContractFactory(
        "MockOnReceive"
      )) as MockOnReceive__factory;
      onRecieve = await mockOnReceiveFactory.deploy(
        erc721.address,
        accs[6].address
      );
      // Mint and transfer to receiver contract
      await erc721.connect(minter).mint(minter.address, 1);
      // Fails as msg.sender != tx.origin
      await expect(
        erc721
          .connect(minter)
          ["safeTransferFrom(address,address,uint256)"](
            minter.address,
            onRecieve.address,
            8
          )
      ).to.be.revertedWith(`'CallerNotInWhitelist("${onRecieve.address}")'`);
    });
  });
});
