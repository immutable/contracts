import type { BigNumber, BigNumberish, BytesLike, CallOverrides, Overrides, PopulatedTransaction } from "ethers";
import type { Provider } from "@ethersproject/providers";

import { ImmutableERC721MintByID__factory } from "../typechain-types/factories/contracts/token/erc721/preset/ImmutableERC721MintByID__factory";
import {
  ImmutableERC721Base,
  ImmutableERC721MintByID,
} from "../typechain-types/contracts/token/erc721/preset/ImmutableERC721MintByID";
import { PromiseOrValue } from "../typechain-types/common";
import { defaultGasOverrides } from "./config/overrides";

// Struct for specifying token IDs to mint to an address.
export type IDMint = ImmutableERC721Base.IDMintStruct;

// Struct for transferring multiple tokens between two addresses.
export type TransferRequest = ImmutableERC721Base.TransferRequestStruct;

// Struct for safe burning multiple tokens from a single address.
export type IDBurn = ImmutableERC721Base.IDBurnStruct;

export class ERC721MintByIDClient {
  private readonly contract: ImmutableERC721MintByID;

  constructor(contractAddress: string) {
    const factory = new ImmutableERC721MintByID__factory();
    this.contract = factory.attach(contractAddress);
  }

  /**
   * Read functions
   */

  /**
   * @returns the DEFAULT_ADMIN_ROLE as a string.
   */
  public async DEFAULT_ADMIN_ROLE(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).DEFAULT_ADMIN_ROLE(overrides);
  }

  /**
   * @returns the MINTER_ROLE as a string.
   */
  public async MINTER_ROLE(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).MINTER_ROLE(overrides);
  }

  /**
   * @returns the balance of an address as a BigNumber.
   */
  public async balanceOf(
    provider: Provider,
    owner: PromiseOrValue<string>,
    overrides: CallOverrides = {},
  ): Promise<BigNumber> {
    return await this.contract.connect(provider).balanceOf(owner, overrides);
  }

  /**
   * @returns the baseURI as a string.
   */
  public async baseURI(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).baseURI(overrides);
  }

  /**
   * @returns the contractURI as a string.
   */
  public async contractURI(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).contractURI(overrides);
  }

  /**
   * @returns admin addresses as an array of strings.
   */
  public async getAdmins(provider: Provider, overrides: CallOverrides = {}): Promise<string[]> {
    return await this.contract.connect(provider).getAdmins(overrides);
  }

  /**
   * @returns the approved address for a token ID, or zero if no address set.
   */
  public async getApproved(
    provider: Provider,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: CallOverrides = {},
  ): Promise<string> {
    return await this.contract.connect(provider).getApproved(tokenId, overrides);
  }

  /**
   * @returns the role admin address.
   */
  public async getRoleAdmin(
    provider: Provider,
    role: PromiseOrValue<BytesLike>,
    overrides: CallOverrides = {},
  ): Promise<string> {
    return await this.contract.connect(provider).getRoleAdmin(role, overrides);
  }

  /**
   * @returns the role member address at a particular index.
   */
  public async getRoleMember(
    provider: Provider,
    role: PromiseOrValue<BytesLike>,
    index: PromiseOrValue<BigNumberish>,
    overrides: CallOverrides = {},
  ): Promise<string> {
    return await this.contract.connect(provider).getRoleMember(role, index, overrides);
  }

  /**
   * @returns the role member count as a BigNumber.
   */
  public async getRoleMemberCount(
    provider: Provider,
    role: PromiseOrValue<BytesLike>,
    overrides: CallOverrides = {},
  ): Promise<BigNumber> {
    return await this.contract.connect(provider).getRoleMemberCount(role, overrides);
  }

  /**
   * @returns a boolean for whether an account has a particular role.
   */
  public async hasRole(
    provider: Provider,
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: CallOverrides = {},
  ): Promise<boolean> {
    return await this.contract.connect(provider).hasRole(role, account, overrides);
  }

  /**
   * @returns a booolean that tells whether an operator is approved by a given owner.
   */
  public async isApprovedForAll(
    provider: Provider,
    owner: PromiseOrValue<string>,
    operator: PromiseOrValue<string>,
    overrides: CallOverrides = {},
  ): Promise<boolean> {
    return await this.contract.connect(provider).isApprovedForAll(owner, operator, overrides);
  }

  /**
   * @returns the name of the contract as a string.
   */
  public async name(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).name(overrides);
  }

  /**
   * @returns the owner address of a particular tokenId.
   */
  public async ownerOf(
    provider: Provider,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: CallOverrides = {},
  ): Promise<string> {
    return await this.contract.connect(provider).ownerOf(tokenId, overrides);
  }

  /**
   * Returns the current nonce of a given token ID.
   * @param tokenId The ID of the token for which to retrieve the nonce.
   * @return Current nonce of the given token.
   */
  public async nonces(
    provider: Provider,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: CallOverrides = {},
  ): Promise<BigNumber> {
    return await this.contract.connect(provider).nonces(tokenId, overrides);
  }

  /**
   * @returns the operator allowlist as a string.
   */
  public async operatorAllowlist(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).operatorAllowlist(overrides);
  }

  /**
   * @returns the royalty information for a particular tokenId.
   */
  public async royaltyInfo(
    provider: Provider,
    _tokenId: PromiseOrValue<BigNumberish>,
    _salePrice: PromiseOrValue<BigNumberish>,
    overrides: CallOverrides = {},
  ): Promise<[string, BigNumber]> {
    return await this.contract.connect(provider).royaltyInfo(_tokenId, _salePrice, overrides);
  }

  /**
   * @returns the symbol of the contract as a string.
   */
  public async symbol(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).symbol(overrides);
  }

  /**
   * @returns the Uniform Resource Identifier (URI) for tokenId token.
   */
  public async tokenURI(
    provider: Provider,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: CallOverrides = {},
  ): Promise<string> {
    return await this.contract.connect(provider).tokenURI(tokenId, overrides);
  }

  /**
   * @returns returns the total amount of tokens stored by the contract.
   */
  public async totalSupply(provider: Provider, overrides: CallOverrides = {}): Promise<BigNumber> {
    return await this.contract.connect(provider).totalSupply(overrides);
  }

  /**
   * Write functions
   */

  /**
   * @returns a populated transaction for the approve contract function
   */
  public async populateApprove(
    to: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.approve(to, tokenId, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * Function to approve by way of owner signature
   * @param spender the address to approve
   * @param tokenId the index of the NFT to approve the spender on
   * @param deadline a timestamp expiry for the permit
   * @param sig a traditional or EIP-2098 signature
   */
  public async populatePermit(
    spender: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    deadline: PromiseOrValue<BigNumberish>,
    sig: PromiseOrValue<BytesLike>,
    overrides: CallOverrides = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.permit(spender, tokenId, deadline, sig, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the burn contract function
   */
  public async populateBurn(
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.burn(tokenId, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the batch burn contract function
   */
  public async populateBurnBatch(
    tokenIds: PromiseOrValue<BigNumberish>[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.burnBatch(tokenIds, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the grantMinterRole contract function
   */
  public async populateGrantMinterRole(
    user: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.grantMinterRole(user, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the grantRole contract function
   */
  public async populateGrantRole(
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.grantRole(role, account, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the mint contract function
   */
  public async populateMint(
    to: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.mint(to, tokenId, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the batch mint contract function
   */
  public async populateSafeMintBatch(
    mints: IDMint[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeMintBatch(mints, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the safe burn contract function
   */
  public async populateSafeBurn(
    owner: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeBurn(owner, tokenId, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the safe burn batch contract function
   */
  public async populateSafeBurnBatch(
    burns: IDBurn[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeBurnBatch(burns, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the renounceRole contract function
   */
  public async populateRenounceRole(
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.renounceRole(role, account, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the revokeMinterRole contract function
   */
  public async populateRevokeMinterRole(
    user: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.revokeMinterRole(user, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the revokeRole contract function
   */
  public async populateRevokeRole(
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.revokeRole(role, account, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the batch save transfer from function
   */
  public async populateSafeTransferFromBatch(
    transfers: TransferRequest,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeTransferFromBatch(transfers, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the safeTransferFrom(address,address,uint256) contract function
   */
  public async "populateSafeTransferFrom(address,address,uint256)"(
    from: PromiseOrValue<string>,
    to: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction["safeTransferFrom(address,address,uint256)"](from, to, tokenId, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the safeTransferFrom(address,address,uint256,bytes) contract function
   */
  public async "populateSafeTransferFrom(address,address,uint256,bytes)"(
    from: PromiseOrValue<string>,
    to: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    data: PromiseOrValue<BytesLike>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction["safeTransferFrom(address,address,uint256,bytes)"](
      from,
      to,
      tokenId,
      data,
      { ...defaultGasOverrides, ...overrides },
    );
  }

  /**
   * @returns a populated transaction for the setApprovalForAll contract function
   */
  public async populateSetApprovalForAll(
    operator: PromiseOrValue<string>,
    approved: PromiseOrValue<boolean>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setApprovalForAll(operator, approved, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the setBaseURI contract function
   */
  public async populateSetBaseURI(
    baseURI_: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setBaseURI(baseURI_, { ...defaultGasOverrides, ...overrides });
  }

  /**
   * @returns a populated transaction for the setContractURI contract function
   */
  public async populateSetContractURI(
    _contractURI: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setContractURI(_contractURI, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the setDefaultRoyaltyReceiver contract function
   */
  public async populateSetDefaultRoyaltyReceiver(
    receiver: PromiseOrValue<string>,
    feeNumerator: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setDefaultRoyaltyReceiver(receiver, feeNumerator, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the setNFTRoyaltyReceiver contract function
   */
  public async populateSetNFTRoyaltyReceiver(
    tokenId: PromiseOrValue<BigNumberish>,
    receiver: PromiseOrValue<string>,
    feeNumerator: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setNFTRoyaltyReceiver(tokenId, receiver, feeNumerator, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }

  /**
   * @returns a populated transaction for the setNFTRoyaltyReceiverBatch contract function
   */
  public async populateSetNFTRoyaltyReceiverBatch(
    tokenIds: PromiseOrValue<BigNumberish>[],
    receiver: PromiseOrValue<string>,
    feeNumerator: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {},
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setNFTRoyaltyReceiverBatch(tokenIds, receiver, feeNumerator, {
      ...defaultGasOverrides,
      ...overrides,
    });
  }
}
