import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ImmutableERC721PermissionedMintable,
  MockMarketplace,
  MockFactory,
  RoyaltyAllowlist,
  MockOnReceive,
  MockOnReceive__factory,
  MockWalletFactory,
} from "../../typechain";
import {
  AllowlistFixture,
  walletSCFixture,
  disguidedEOAFixture,
} from "../utils/DeployFixtures";

describe("Allowlisted ERC721 Transfers", function () {
  this.timeout(300_000); // 5 min

  let erc721: ImmutableERC721PermissionedMintable;
  let walletFactory: MockWalletFactory;
  let factory: MockFactory;
  let royaltyAllowlist: RoyaltyAllowlist;
  let marketPlace: MockMarketplace;
  let deployedAddr: string; // deployed SC wallet address
  let moduleAddress: string;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let registrar: SignerWithAddress;
  let scWallet: SignerWithAddress;
  let accs: SignerWithAddress[];

  before(async function () {
    [owner, minter, registrar, scWallet, ...accs] = await ethers.getSigners();

    // Get all required contracts
    ({ erc721, walletFactory, factory, royaltyAllowlist, marketPlace } =
      await AllowlistFixture(owner));
    // Deploy the wallet fixture

    ({ deployedAddr, moduleAddress } = await walletSCFixture(
      scWallet,
      walletFactory
    ));

    // Set up roles
    await erc721.connect(owner).grantMinterRole(minter.address);
    await royaltyAllowlist.connect(owner).grantRegistrarRole(registrar.address);
  });

  describe("Royalty Allowlist Registry setting", function () {
    it("Should set the Allowlist registry to a contract the implements the IRoyaltyAllowlist interface", async function () {
      await expect(
        erc721
          .connect(owner)
          .setRoyaltyAllowlistRegistry(royaltyAllowlist.address)
      )
        .to.emit(erc721, "RoyaltytAllowlistRegistryUpdated")
        .withArgs(ethers.constants.AddressZero, royaltyAllowlist.address);

      expect(await erc721.royaltyAllowlist()).to.equal(
        royaltyAllowlist.address
      );
    });

    it("Should not allow contracts that do not implement the IRoyaltyAllowlist to be set", async function () {
      // Deploy another contract that implements IERC165, but not IRoyaltyAllowlist
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
        erc721.connect(owner).setRoyaltyAllowlistRegistry(erc721Two.address)
      ).to.be.revertedWith("contract does not implement IRoyaltyAllowlist");
    });

    it("Should not allow a non-admin to access the function to update the registry", async function () {
      await expect(
        erc721
          .connect(registrar)
          .setRoyaltyAllowlistRegistry(royaltyAllowlist.address)
      ).to.be.revertedWith(
        "AccessControl: account 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });

  describe("Approvals", function () {
    it("Should not allow a non-Allowlisted operator to be approved", async function () {
      // Approve for all
      await expect(
        erc721.connect(minter).setApprovalForAll(marketPlace.address, true)
      ).to.be.revertedWith(
        `'ApproveTargetNotInAllowlist("${marketPlace.address}")'`
      );
      // Approve
      await expect(
        erc721.connect(minter).approve(marketPlace.address, 1)
      ).to.be.revertedWith(
        `'ApproveTargetNotInAllowlist("${marketPlace.address}")'`
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

    it("Should allow Allowlisted addresses to be approved", async function () {
      // Add the mock marketplace to registry
      await royaltyAllowlist
        .connect(registrar)
        .addAddressToAllowlist([marketPlace.address]);
      // Approve marketplace on erc721 contract
      await erc721.connect(minter).approve(marketPlace.address, 2);
      await erc721.connect(minter).setApprovalForAll(marketPlace.address, true);
      expect(await erc721.getApproved(2)).to.be.equal(marketPlace.address);
      expect(await erc721.isApprovedForAll(minter.address, marketPlace.address))
        .to.be.true;
    });

    it("Should allow Allowlisted smart contract wallets to be approved", async function () {
      // Allowlist the bytecode
      await royaltyAllowlist
        .connect(registrar)
        .addWalletToAllowlist(deployedAddr);
      await erc721.connect(minter).approve(deployedAddr, 3);
      // Approve the smart contract wallet
      await erc721.connect(minter).setApprovalForAll(deployedAddr, true);
      expect(await erc721.getApproved(3)).to.be.equal(deployedAddr);
      expect(await erc721.isApprovedForAll(minter.address, deployedAddr)).to.be
        .true;
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

    it("Should not block transfers from an allow listed contract", async function () {
      // mock marketplace has already been approved
      expect(await erc721.balanceOf(accs[3].address)).to.be.equal(0);
      await marketPlace.connect(minter).executeTransfer(accs[3].address, 2);
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
      const deployedAddrTwo = await walletFactory.getAddress(
        moduleAddress,
        saltTwo
      );
      const deployedAddrThree = await walletFactory.getAddress(
        moduleAddress,
        saltThree
      );
      // Mint NFTs to the wallets
      await erc721.connect(minter).mint(deployedAddr, 1);
      await erc721.connect(minter).mint(deployedAddrTwo, 1);

      // Connect to wallets
      const wallet = await ethers.getContractAt("MockWallet", deployedAddr);
      const walletTwo = await ethers.getContractAt(
        "MockWallet",
        deployedAddrTwo
      );
      const walletThree = await ethers.getContractAt(
        "MockWallet",
        deployedAddrThree
      );

      // Transfer between wallets
      await wallet.transferNFT(
        erc721.address,
        deployedAddr,
        deployedAddrThree,
        6
      );
      await walletTwo.transferNFT(
        erc721.address,
        deployedAddrTwo,
        deployedAddrThree,
        7
      );
      expect(await erc721.balanceOf(deployedAddr)).to.be.equal(0);
      expect(await erc721.balanceOf(deployedAddrTwo)).to.be.equal(0);
      expect(await erc721.balanceOf(deployedAddrThree)).to.be.equal(2);
      await walletThree.transferNFT(
        erc721.address,
        deployedAddrThree,
        deployedAddr,
        6
      );
      await walletThree.transferNFT(
        erc721.address,
        deployedAddrThree,
        deployedAddrTwo,
        7
      );
      expect(await erc721.balanceOf(deployedAddr)).to.be.equal(1);
      expect(await erc721.balanceOf(deployedAddrTwo)).to.be.equal(1);
      expect(await erc721.balanceOf(deployedAddrThree)).to.be.equal(0);
    });
  });

  describe("Malicious Contracts", function () {
    // The EOA disguise attack vector is a where a pre-computed CREATE2 deterministic address is disguised as an EOA.
    // By virtue of this, approvals and transfers to this address will pass. We need to catch actions from this address
    // once it is deployed.
    it("EOA disguise approve", async function () {
      // This attack vector is where a CFA is approved prior to deployment. This passes as at the time of approval as
      // the CFA is treated as an EOA, passing _validateApproval.
      // This means post-deployment that the address is now an approved operator
      // and is able to call transferFrom.
      let deployedAddr;
      let salt;
      let constructorByteCode;

      ({ deployedAddr, salt, constructorByteCode } = await disguidedEOAFixture(
        erc721.address,
        factory,
        "0x1234"
      ));
      // Approve disguised EOA
      await erc721.connect(minter).mint(minter.address, 1);
      await erc721.connect(minter).setApprovalForAll(deployedAddr, true);
      // Deploy disguised EOA
      await factory.connect(accs[5]).deploy(salt, constructorByteCode);
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
          .executeTransfer(minter.address, accs[5].address, 8)
      ).to.be.revertedWith(`'CallerNotInAllowlist("${deployedAddr}")'`);
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
      ).to.be.revertedWith(`'CallerNotInAllowlist("${onRecieve.address}")'`);
    });
  });
});
