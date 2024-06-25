# Test Plan for Immutable ERC1155 Preset contracts

## ImmutableERC1155.sol
This section defines tests for contracts/erc1155/preset/ImmutableERC1155.sol Note
that this contract extends Open Zeppelin's ERC 1155 contract which is extensively tested here:
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/release-v4.9/test/token/ERC1155 .

All the tests defined in the table below are in test/token/erc1155/ImmutableERC1155.t.sol.

| Test name                                                   | Description                                                                                      | Happy Case | Implemented |
|-------------------------------------------------------------|--------------------------------------------------------------------------------------------------|------------|-------------|
| test_ValidateDeploymentConstructor                          | Validate constructor logic.                                                                      | Yes        | Yes         |
| test_DeploymentShouldSetAdminRoleToOwner                    | Check contract owner is given admin role.                                                        | Yes        | Yes         |
| test_DeploymentShouldSetContractURI                         | Check contract's URI is correct.                                                                 | Yes        | Yes         |
| test_DeploymentShouldSetBaseURI                             | Check contract's base URI is correct.                                                            | Yes        | Yes         |
| test_DeploymentAllowlistShouldGiveAdminToOwner              | Check that contract owner has admin role in Operator Allow List contract.                        | Yes        | Yes         |
| test_DeploymentShouldSetAllowlistToProxy                    | Check that Operator Allow List contract address is set correctly.                                | Yes        | Yes         |
| test_AdminRoleCanSetContractURI                             | Admin can modify contract URI.                                                                   | Yes        | Yes         |
| test_RevertIfNonAdminAttemptsToSetContractURI               | Non admin is unable to modify contract URI.                                                      | No         | Yes         |
| test_AdminRoleCanSetBaseURI                                 | Admin can modify base URI.                                                                       | Yes        | Yes         |
| test_RevertIfNonAdminAttemptsToSetBaseURI                   | Non admin is unable to modify base URI.                                                          | No         | Yes         |
| test_PermitSuccess                                          | Ensure Permit works                                                                              | Yes        | Yes         |
| test_PermitRevertsWhenInvalidNonce                          | Ensure Permit requires valid nonce                                                               | No         | Yes         |
| test_PermitRevertsWhenInvalidSigner                         | Ensure Permit requires valid signer                                                              | No         | Yes         |
| test_PermitRevertsWhenDeadlineExceeded                      | Ensure Permit respects the deadline                                                              | No         | Yes         |
| test_PermitRevertsWhenInvalidSignature                      | Ensure Permit validates the signature                                                            | No         | Yes         |
| test_PermitSuccess_UsingSmartContractWalletAsOwner          | Ensure Permit works when using a smart contract wallet as the owner                              | Yes        | Yes         |
| test_MinterRoleCanMint                                      | Ensure successful minting by minter                                                              | Yes        | Yes         |
| test_MinterRoleCanBatchMint                                 | Ensure successful batch minting by minter                                                        | Yes        | Yes         |
| test_ApprovedOperatorTransferFrom                           | Check that operator can transfer tokens on behalf of owner                                       | Yes        | Yes         |
| test_ApprovedOperatorBatchTransferFrom                      | Check that operator can batch transfer tokens on behalf of owner                                 | Yes        | Yes         |
| test_ApprovedSCWOperatorTransferFromToApprovedReceiver      | Check that smart contract wallet operator can transfer tokens to an approved receiver            | Yes        | Yes         |
| test_ApprovedSCWOperatorBatchTransferFromToApprovedReceiver | Check that smart contract wallet operator can batch transfer tokens to an approved receiver      | Yes        | Yes         |
| test_ApprovedSCWOperatorTransferFromToUnApprovedReceiver    | Check that smart contract wallet operator is unable to transfer tokens to an unapproved receiver | No         | Yes         |
| test_UnapprovedSCWOperatorTransferFrom                      | Ensure that an unapproved smart contract wallet is unable to transfer tokens                     | No         | Yes         |
| test_Burn                                                   | Check that owner can burn tokens                                                                 | Yes        | Yes         |
| test_BatchBurn                                              | Check that owner can batch burn tokens                                                           | Yes        | Yes         |
| test_SupportsInterface                                      | Check that supports interface works                                                              | Yes        | Yes         |
| test_SupportsInterface_delegatesToSuper                     | Supports interface is delegated to super for unknown values                                      | Yes        | Yes         |
| test_setDefaultRoyaltyReceiver                              | Check that the default royalties are set correctly                                               | Yes        | Yes         |
| test_setNFTRoyaltyReceiver                                  | Check that a given NFT can have its royalty values overriden                                     | Yes        | Yes         |
| test_setNFTRoyaltyReceiverBatch                             | Check that a batch of NFTs can have their royalty values overriden                               | Yes        | Yes         |
