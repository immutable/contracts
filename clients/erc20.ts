import { Overrides } from "ethers";
import { Provider } from "@ethersproject/providers";
import { BigNumberish, BigNumber } from "@ethersproject/bignumber";
import { CallOverrides, PopulatedTransaction } from "@ethersproject/contracts";

import { ERC20 } from "../typechain-types/@openzeppelin/contracts/token/ERC20";
import { ERC20__factory } from "../typechain-types/factories/@openzeppelin/contracts/token/ERC20/ERC20__factory";
import { PromiseOrValue } from "../typechain-types/common";
import { defaultGasOverrides } from "./config/overrides";

export class ERC20Client {
  private readonly contract: ERC20;

  constructor(contractAddress: string) {
    const factory = new ERC20__factory();
    this.contract = factory.attach(contractAddress);
  }

  /**
   * @returns a promise that resolves with a BigNumber that represents the amount of tokens in existence
   */
  public async totalSupply(provider: Provider, overrides: CallOverrides = {}): Promise<BigNumber> {
    return this.contract.connect(provider).totalSupply(overrides);
  }

  /**
   * @returns a promise that resolves with a BigNumber that represents the amount of tokens owned by account
   */
  public async balanceOf(
    provider: Provider,
    account: PromiseOrValue<string>,
    overrides: CallOverrides = {}
  ): Promise<BigNumber> {
    return this.contract.connect(provider).balanceOf(account, overrides);
  }

  /**
   * @returns a promise that resolves with a BigNumber that represents the remaining number of tokens that spender will be allowed to spend on behalf of owner through transferFrom
   */
  public async allowance(
    provider: Provider,
    owner: PromiseOrValue<string>,
    spender: PromiseOrValue<string>,
    overrides: CallOverrides = {}
  ): Promise<BigNumber> {
    return this.contract.connect(provider).allowance(owner, spender, overrides);
  }

  /**
   * @returns a promise that resolves with a populated transaction
   */
  public async populateTransfer(
    to: PromiseOrValue<string>,
    amount: PromiseOrValue<BigNumberish>,
    overrides: Overrides & { from?: PromiseOrValue<string> } = {}
  ): Promise<PopulatedTransaction> {
    return this.contract.populateTransaction.transfer(to, amount, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a promise that resolves with a populated transaction
   */
  public async populateApprove(
    spender: PromiseOrValue<string>,
    amount: PromiseOrValue<BigNumberish>,
    overrides: Overrides & { from?: PromiseOrValue<string> } = {}
  ): Promise<PopulatedTransaction> {
    return this.contract.populateTransaction.approve(spender, amount, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a promise that resolves with a populated transaction
   */
  public async populateTransferFrom(
    from: PromiseOrValue<string>,
    to: PromiseOrValue<string>,
    amount: PromiseOrValue<BigNumberish>,
    overrides: Overrides & { from?: PromiseOrValue<string> } = {}
  ): Promise<PopulatedTransaction> {
    return this.contract.populateTransaction.transferFrom(from, to, amount, { ...defaultGasOverrides, ...overrides });
  }
}
