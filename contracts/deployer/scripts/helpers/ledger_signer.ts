// Copied from https://github.com/immutable/imx-engine/blob/77b8a62e6ac0baf033519e0ed533316eead3bc23/services/order-book-mr/e2e/scripts/ledger-signer.ts
import { ethers } from "ethers";
import Eth from "@ledgerhq/hw-app-eth";
import TransportNodeHid from "@ledgerhq/hw-transport-node-hid";
import {
  defineReadOnly,
  hexlify,
  resolveProperties,
  serializeTransaction,
  toUtf8Bytes,
  UnsignedTransaction,
} from "ethers/lib/utils";
import { toBuffer, toRpcSig } from "@nomicfoundation/ethereumjs-util";
import ledgerService from "@ledgerhq/hw-app-eth/lib/services/ledger";

const DEFAULT_LEDGER_PATH = "m/44'/60'/0'/0/0";

function toHex(value: string | Buffer): string {
  const stringValue = typeof value === "string" ? value : value.toString("hex");
  return stringValue.startsWith("0x") ? stringValue : `0x${stringValue}`;
}

// Simple LedgerSigner that wraps @ledgerhq/hw-transport-node-hid to deploy
// contracts using hardware wallet.
export class LedgerSigner extends ethers.Signer {
  readonly path: string;
  readonly _eth: Promise<Eth> | undefined;

  constructor(
    provider?: ethers.providers.Provider,
    path: string = DEFAULT_LEDGER_PATH
  ) {
    super();
    this.path = path || DEFAULT_LEDGER_PATH;

    defineReadOnly(this, "path", path);
    defineReadOnly(this, "provider", provider || undefined);
    defineReadOnly(
      this,
      "_eth",
      TransportNodeHid.create().then(async (transport) => {
        try {
          const eth = new Eth(transport);
          await eth.getAppConfiguration();
          return eth;
        } catch (error) {
          throw "LedgerSigner: unable to initialize TransportNodeHid: " + error;
        }
      })
    );
  }

  private async _withConfirmation<T extends (...args: any) => any>(
    func: T
  ): Promise<ReturnType<T>> {
    try {
      const result = await func();

      return result;
    } catch (error) {
      throw new Error("LedgerSigner: confirmation_failure: " + error);
    }
  }

  public async getAddress(): Promise<string> {
    const eth = await this._eth;

    const MAX_RETRY_COUNT = 50;
    const WAIT_INTERVAL = 100;

    for (let i = 0; i < MAX_RETRY_COUNT; i++) {
      try {
        const account = await eth!.getAddress(this.path);
        return ethers.utils.getAddress(account.address);
      } catch (error) {
        if ((error as any).id !== "TransportLocked") {
          throw error;
        }
      }
      await new Promise((resolve) => setTimeout(resolve, WAIT_INTERVAL));
    }

    throw new Error("LedgerSigner: getAddress timed out");
  }

  public async signMessage(
    message: ethers.utils.Bytes | string
  ): Promise<string> {
    const resolvedMessage =
      typeof message === "string" ? toUtf8Bytes(message) : message;

    const eth = await this._eth;
    const signature = await this._withConfirmation(() =>
      eth!.signPersonalMessage(this.path, hexlify(resolvedMessage))
    );

    return toRpcSig(
      BigInt(signature.v - 27),
      toBuffer(toHex(signature.r)),
      toBuffer(toHex(signature.s))
    );
  }

  async signTransaction(
    transaction: ethers.providers.TransactionRequest
  ): Promise<string> {
    const txRequest = await resolveProperties(transaction);

    const baseTx: UnsignedTransaction = {
      type: txRequest.type,
      data: txRequest.data,
      chainId: txRequest.chainId,
      gasLimit: txRequest.gasLimit,
      gasPrice: txRequest.gasPrice,
      nonce: Number(txRequest.nonce),
      value: txRequest.value,
      to: txRequest.to,
    };

    // Type-2 transaction, with tip
    if (txRequest.type === 2) {
      baseTx.maxFeePerGas = txRequest.maxFeePerGas;
      baseTx.maxPriorityFeePerGas = txRequest.maxPriorityFeePerGas;
    }

    const txToSign = serializeTransaction(baseTx).substring(2);

    const resolution = await ledgerService.resolveTransaction(txToSign, {}, {});

    const eth = await this._eth;
    const signature = await this._withConfirmation(() =>
      eth!.signTransaction(this.path, txToSign, resolution)
    );

    return serializeTransaction(baseTx, {
      v: Number(signature.v),
      r: toHex(signature.r),
      s: toHex(signature.s),
    });
  }

  connect(provider: ethers.providers.Provider): ethers.Signer {
    return new LedgerSigner(provider, this.path);
  }

  public async close() {
    (await this._eth)?.transport.close();
  }
}