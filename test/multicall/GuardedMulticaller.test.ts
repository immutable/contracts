import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumberish } from "ethers";
import moment from "moment";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { randomUUID } from "crypto";
import { hexlify, keccak256 } from "ethers/lib/utils";
import { GuardedMulticaller, MockFunctions } from "../../typechain-types";

describe("GuardedMulticaller", function () {
  let deployerAccount: SignerWithAddress;
  let signerAccount: SignerWithAddress;
  let userAccount: SignerWithAddress;

  before(async function () {
    [deployerAccount, signerAccount, userAccount] = await ethers.getSigners();
  });

  const multicallerName = "Multicaller";
  const multicallerVersion = "v1";

  let guardedMulticaller: GuardedMulticaller;
  let deadline: number;
  let ref: string;
  let domain: { name: string; version: string; verifyingContract: string };

  beforeEach(async function () {
    const GuardedMulticallerFactory = await ethers.getContractFactory("GuardedMulticaller");
    guardedMulticaller = (await GuardedMulticallerFactory.deploy(
      deployerAccount.address,
      multicallerName,
      multicallerVersion,
    )) as GuardedMulticaller;
    await guardedMulticaller.connect(deployerAccount).grantMulticallSignerRole(signerAccount.address);
    deadline = moment.utc().add(30, "minute").unix();
    ref = `0x${randomUUID().replace(/-/g, "").padEnd(64, "0")}`;
    domain = {
      name: multicallerName,
      version: multicallerVersion,
      verifyingContract: guardedMulticaller.address,
    };
  });

  describe("Mock Functions", function () {
    let mock: MockFunctions;

    beforeEach(async function () {
      const MockFunctionsFactory = await ethers.getContractFactory("MockFunctions");
      mock = (await MockFunctionsFactory.connect(deployerAccount).deploy()) as MockFunctions;
      await guardedMulticaller.setFunctionPermits([
        {
          target: mock.address,
          functionSelector: funcSignatureToFuncSelector("succeed()"),
          permitted: true,
        },
        {
          target: mock.address,
          functionSelector: funcSignatureToFuncSelector("revertWithNoReason()"),
          permitted: true,
        },
      ]);
    });

    it("Should successfully execute if valid", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      )
        .to.emit(guardedMulticaller, "Multicalled")
        .withArgs(signerAccount.address, ref, targets, data, deadline);
    });

    it("Should revert with custom error with empty return data", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("revertWithNoReason", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("FailedCall");
    });

    it("Should revert if deadline has passed", async function () {
      const expiredDeadline = moment.utc().subtract(30, "minute").unix();
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, expiredDeadline, domain);
      await expect(
        guardedMulticaller
          .connect(userAccount)
          .execute(signerAccount.address, ref, targets, data, expiredDeadline, sig),
      ).to.be.revertedWith("Expired");
    });

    it("Should revert if reference is reused - anti-replay", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("ReusedReference");
    });

    it("Should revert if ref is invalid", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      const invalidRef = `0x${"0".repeat(64)}`;
      await expect(
        guardedMulticaller
          .connect(userAccount)
          .execute(signerAccount.address, invalidRef, targets, data, deadline, sig),
      ).to.be.revertedWith("InvalidReference");
    });

    it("Should revert if signer does not have MULTICALLER role", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(userAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(userAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("UnauthorizedSigner");
    });

    it("Should revert if signer and signature do not match", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(userAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("UnauthorizedSignature");
    });

    it("Should revert if targets are empty", async function () {
      const targets: string[] = [];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("EmptyAddressArray");
    });

    it("Should revert if targets and data sizes do not match", async function () {
      const targets = [mock.address, mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("AddressDataArrayLengthsMismatch");
    });

    it("Should revert if function not permitted", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("nonPermitted", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("UnauthorizedFunction");
    });

    it("Should revert if function is disallowed", async function () {
      await guardedMulticaller.setFunctionPermits([
        {
          target: mock.address,
          functionSelector: funcSignatureToFuncSelector("succeed()"),
          permitted: false,
        },
      ]);
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("UnauthorizedFunction");
    });

    it("Should revert if signature is invalid", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const maliciousRef = `0x${randomUUID().replace(/-/g, "").padEnd(64, "0")}`;
      const sig = await signMulticallTypedData(signerAccount, maliciousRef, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      ).to.be.revertedWith("UnauthorizedSignature");
    });

    it("Should emit FunctionPermitted event when setting function permits", async function () {
      await expect(
        guardedMulticaller.connect(deployerAccount).setFunctionPermits([
          {
            target: mock.address,
            functionSelector: funcSignatureToFuncSelector("succeed()"),
            permitted: true,
          },
        ]),
      )
        .to.emit(guardedMulticaller, "FunctionPermitted")
        .withArgs(mock.address, funcSignatureToFuncSelector("succeed()"), true);
      await expect(
        guardedMulticaller.connect(deployerAccount).setFunctionPermits([
          {
            target: mock.address,
            functionSelector: funcSignatureToFuncSelector("succeed()"),
            permitted: false,
          },
        ]),
      )
        .to.emit(guardedMulticaller, "FunctionPermitted")
        .withArgs(mock.address, funcSignatureToFuncSelector("succeed()"), false);
    });

    it("Should revert if setting function permits with invalid data", async function () {
      await expect(guardedMulticaller.connect(deployerAccount).setFunctionPermits([])).to.be.revertedWith(
        "EmptyFunctionPermitArray",
      );
      await expect(
        guardedMulticaller.connect(userAccount).setFunctionPermits([
          {
            target: mock.address,
            functionSelector: funcSignatureToFuncSelector("succeed()"),
            permitted: false,
          },
        ]),
      ).to.be.revertedWith(/AccessControl/);
      await expect(
        guardedMulticaller.setFunctionPermits([
          {
            target: deployerAccount.address,
            functionSelector: funcSignatureToFuncSelector("succeed()"),
            permitted: true,
          },
        ]),
      ).to.be.revertedWith("NonContractAddress");
    });

    it("Should revert if grant/revoke signer role with invalid role", async function () {
      await expect(
        guardedMulticaller.connect(userAccount).grantMulticallSignerRole(userAccount.address),
      ).to.be.revertedWith(/AccessControl/);

      await expect(
        guardedMulticaller.connect(userAccount).revokeMulticallSignerRole(userAccount.address),
      ).to.be.revertedWith(/AccessControl/);
    });

    it("Should return hasBeenExecuted = true if the call has been executed", async function () {
      const targets = [mock.address];
      const data = [mock.interface.encodeFunctionData("succeed", [])];
      const sig = await signMulticallTypedData(signerAccount, ref, targets, data, deadline, domain);
      await expect(
        guardedMulticaller.connect(userAccount).execute(signerAccount.address, ref, targets, data, deadline, sig),
      )
        .to.emit(guardedMulticaller, "Multicalled")
        .withArgs(signerAccount.address, ref, targets, data, deadline);

      await expect(await guardedMulticaller.hasBeenExecuted(ref)).to.be.true;
    });

    it("Should return hasBeenExecuted = false for an unknown reference", async function () {
      const invalidRef = `0x${randomUUID().replace(/-/g, "").padEnd(64, "0")}`;
      await expect(await guardedMulticaller.hasBeenExecuted(invalidRef)).to.be.false;
    });
  });
});

function funcSignatureToFuncSelector(funcSignature: string): string {
  return keccak256(hexlify(ethers.utils.toUtf8Bytes(funcSignature))).substring(0, 10);
}

async function signMulticallTypedData(
  wallet: SignerWithAddress,
  ref: string,
  targets: string[],
  data: string[],
  deadline: BigNumberish,
  domain: { name: string; version: string; verifyingContract: string },
): Promise<string> {
  return await wallet._signTypedData(
    {
      name: domain.name,
      version: domain.version,
      chainId: await wallet.getChainId(),
      verifyingContract: domain.verifyingContract,
    },
    {
      Multicall: [
        {
          name: "ref",
          type: "bytes32",
        },
        {
          name: "targets",
          type: "address[]",
        },
        {
          name: "data",
          type: "bytes[]",
        },
        {
          name: "deadline",
          type: "uint256",
        },
      ],
    },
    { ref, targets, data, deadline },
  );
}
