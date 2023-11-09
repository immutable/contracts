import type { BigNumber, BigNumberish, BytesLike, CallOverrides, Overrides, PopulatedTransaction } from "ethers";
import type { Provider } from "@ethersproject/providers";

import { ImmutableERC721, ImmutableERC721__factory } from "../typechain-types";
import { ERC721Hybrid } from "../typechain-types/contracts/token/erc721/preset/ImmutableERC721";
import { PromiseOrValue } from "../typechain-types/common";

// Struct for specifying token IDs to mint to an address, by quantity.
export type Mint = ERC721Hybrid.MintStruct;

// Struct for specifying token IDs to mint to an address.
export type IDMint = ERC721Hybrid.IDMintStruct;

// Struct for transferring multiple tokens between two addresses.
export type TransferRequest = ERC721Hybrid.TransferRequestStruct;

// Struct for burning multiple tokens from the same address
export type IDBurn = ERC721Hybrid.IDBurnStruct;

export class ERC721Client {
  private readonly contract: ImmutableERC721;

  constructor(contractAddress: string) {
    const factory = new ImmutableERC721__factory();
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
   * Returns the domain separator used in the encoding of the signature for permits, as defined by EIP-712
   * @return the bytes32 domain separator
   */
  public async DOMAIN_SEPARATOR(provider: Provider, overrides: CallOverrides = {}): Promise<string> {
    return await this.contract.connect(provider).DOMAIN_SEPARATOR(overrides);
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
    overrides: CallOverrides = {}
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
   * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
   * signature.
   */
  public async eip712Domain(
    provider: Provider,
    overrides: CallOverrides = {}
  ): Promise<
    [string, string, string, BigNumber, string, string, BigNumber[]] & {
      fields: string;
      name: string;
      version: string;
      chainId: BigNumber;
      verifyingContract: string;
      salt: string;
      extensions: BigNumber[];
    }
  > {
    return await this.contract.connect(provider).eip712Domain(overrides);
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
    overrides: CallOverrides = {}
  ): Promise<string> {
    return await this.contract.connect(provider).getApproved(tokenId, overrides);
  }

  /**
   * @returns the role admin address.
   */
  public async getRoleAdmin(
    provider: Provider,
    role: PromiseOrValue<BytesLike>,
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
  ): Promise<string> {
    return await this.contract.connect(provider).getRoleMember(role, index, overrides);
  }

  /**
   * @returns the role member count as a BigNumber.
   */
  public async getRoleMemberCount(
    provider: Provider,
    role: PromiseOrValue<BytesLike>,
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
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
    overrides: CallOverrides = {}
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
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.approve(to, tokenId, overrides);
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
    overrides: CallOverrides = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.permit(spender, tokenId, deadline, sig, overrides);
  }

  /**
   * @returns a populated transaction for the burn contract function
   */
  public async populateBurn(
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.burn(tokenId, overrides);
  }

  /**
   * @returns a populated transaction for the batch burn contract function
   */
  public async populateBurnBatch(
    tokenIds: PromiseOrValue<BigNumberish>[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.burnBatch(tokenIds, overrides);
  }

  /**
   * @returns a populated transaction for the safe burn contract function
   */
  public async populateSafeBurn(
    owner: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeBurn(owner, tokenId, overrides);
  }

  /**
   * @returns a populated transaction for the safe burn batch contract function
   */
  public async populateSafeBurnBatch(
    burns: IDBurn[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeBurnBatch(burns, overrides);
  }

  /**
   * @returns a populated transaction for the grantMinterRole contract function
   */
  public async populateGrantMinterRole(
    user: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.grantMinterRole(user, overrides);
  }

  /**
   * @returns a populated transaction for the grantRole contract function
   */
  public async populateGrantRole(
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.grantRole(role, account, overrides);
  }

  /**
   * @returns a populated transaction for the mint by ID contract function
   */
  public async populateMint(
    to: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.mint(to, tokenId, overrides);
  }

  /**
   * @returns a populated transaction for the safe mint by ID contract function
   */
  public async populateSafeMint(
    to: PromiseOrValue<string>,
    tokenId: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeMint(to, tokenId, overrides);
  }

  /**
   * @returns a populated transaction for the mint by quantity contract function
   */
  public async populateMintByQuantity(
    to: PromiseOrValue<string>,
    quantity: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.mintByQuantity(to, quantity, overrides);
  }

  /**
   * @returns a populated transaction for the safe mint by quantity contract function
   */
  public async populateSafeMintByQuantity(
    to: PromiseOrValue<string>,
    quantity: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeMintByQuantity(to, quantity, overrides);
  }

  /**
   * @returns a populated transaction for the batch mint by quantity contract function
   */
  public async populateMintBatchByQuantity(
    mints: Mint[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.mintBatchByQuantity(mints, overrides);
  }

  /**
   * @returns a populated transaction for the batch safe mint by quantity contract function
   */
  public async populateSafeMintBatchByQuantity(
    mints: Mint[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeMintBatchByQuantity(mints, overrides);
  }

  /**
   * @returns a populated transaction for the batch mint by ID to multiple recipients contract function
   */
  public async populateMintBatch(
    mints: IDMint[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.mintBatch(mints, overrides);
  }

  /**
   * @returns a populated transaction for the batch safe mint by ID to multiple recipients contract function
   */
  public async populateSafeMintBatch(
    mints: IDMint[],
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeMintBatch(mints, overrides);
  }

  /**
   * @returns a populated transaction for the renounceRole contract function
   */
  public async populateRenounceRole(
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.renounceRole(role, account, overrides);
  }

  /**
   * @returns a populated transaction for the revokeMinterRole contract function
   */
  public async populateRevokeMinterRole(
    user: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.revokeMinterRole(user, overrides);
  }

  /**
   * @returns a populated transaction for the revokeRole contract function
   */
  public async populateRevokeRole(
    role: PromiseOrValue<BytesLike>,
    account: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.revokeRole(role, account, overrides);
  }

  /**
   * @returns a populated transaction for the batch save transfer from function
   */
  public async populateSafeTransferFromBatch(
    transfers: TransferRequest,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.safeTransferFromBatch(transfers, overrides);
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
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction["safeTransferFrom(address,address,uint256)"](
      from,
      to,
      tokenId,
      overrides
    );
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
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction["safeTransferFrom(address,address,uint256,bytes)"](
      from,
      to,
      tokenId,
      data,
      overrides
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
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setApprovalForAll(operator, approved, overrides);
  }

  /**
   * @returns a populated transaction for the setBaseURI contract function
   */
  public async populateSetBaseURI(
    baseURI_: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setBaseURI(baseURI_, overrides);
  }

  /**
   * @returns a populated transaction for the setContractURI contract function
   */
  public async populateSetContractURI(
    _contractURI: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setContractURI(_contractURI, overrides);
  }

  /**
   * @returns a populated transaction for the setDefaultRoyaltyReceiver contract function
   */
  public async populateSetDefaultRoyaltyReceiver(
    receiver: PromiseOrValue<string>,
    feeNumerator: PromiseOrValue<BigNumberish>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setDefaultRoyaltyReceiver(receiver, feeNumerator, overrides);
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
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setNFTRoyaltyReceiver(tokenId, receiver, feeNumerator, overrides);
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
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setNFTRoyaltyReceiverBatch(
      tokenIds,
      receiver,
      feeNumerator,
      overrides
    );
  }

  /**
   * @returns a populated transaction for the setOperatorAllowlistRegistry contract function
   */
  public async populateSetOperatorAllowlistRegistry(
    _operatorAllowlist: PromiseOrValue<string>,
    overrides: Overrides & {
      from?: PromiseOrValue<string>;
    } = {}
  ): Promise<PopulatedTransaction> {
    return await this.contract.populateTransaction.setOperatorAllowlistRegistry(_operatorAllowlist, overrides);
  }
}
