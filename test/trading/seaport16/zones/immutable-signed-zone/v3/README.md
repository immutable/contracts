# Test Plan for Immutable Signed Zone (v3)

## ImmutableSignedZoneV3.sol

Constructor tests:

| Test name                                                     | Description                                                   | Happy Case | Implemented |
| ------------------------------------------------------------- | ------------------------------------------------------------- | ---------- | ----------- |
| `test_contructor_grantsAdminRoleToOwner`                      | Check `DEFAULT_ADMIN_ROLE` is granted to the specified owner. | Yes        | Yes         |
| `test_contructor_emitsSeaportCompatibleContractDeployedEvent` | Emits `SeaportCompatibleContractDeployed` event.              | Yes        | Yes         |

Control function tests:

| Test name                                                                      | Description                                     | Happy Case | Implemented |
| ------------------------------------------------------------------------------ | ----------------------------------------------- | ---------- | ----------- |
| `test_grantRole_revertsIfCalledByNonAdminRole`                                 | Grant role without authorization                | No         | Yes         |
| `test_grantRole_grantsIfCalledByAdminRole`                                     | Grant role with authorization                   | Yes        | Yes         |
| `test_revokeRole_revertsIfCalledByNonAdminRole`                                | Revoke role without authorization               | No         | Yes         |
| `test_revokeRole_revertsIfRevokingLastDefaultAdminRole`                        | Revoke last `DEFAULT_ADMIN_ROLE`.               | No         | Yes         |
| `test_revokeRole_revokesIfRevokingNonLastDefaultAdminRole`                     | Revoke non-last `DEFAULT_ADMIN_ROLE`.           | Yes        | Yes         |
| `test_revokeRole_revokesIfRevokingLastNonDefaultAdminRole`                     | Revoke last non-`DEFAULT_ADMIN_ROLE`.           | Yes        | Yes         |
| `test_renounceRole_revertsIfCallerDoesNotMatchCallerConfirmationAddress`       | Renounce role without authorization             | No         | Yes         |
| `test_renounceRole_revertsIfRenouncingLastDefaultAdminRole`                    | Renounce last `DEFAULT_ADMIN_ROLE`.             | No         | Yes         |
| `test_renounceRole_revokesIfRenouncingNonLastDefaultAdminRole`                 | Renounce non-last `DEFAULT_ADMIN_ROLE`.         | Yes        | Yes         |
| `test_renounceRole_revokesIfRenouncingLastNonDefaultAdminRole`                 | Renounce last non-`DEFAULT_ADMIN_ROLE`.         | Yes        | Yes         |
| `test_addSigner_revertsIfCalledByNonZoneManagerRole`                           | Add signer without authorization.               | No         | Yes         |
| `test_addSigner_revertsIfSignerIsTheZeroAddress`                               | Add zero address as signer.                     | No         | Yes         |
| `test_addSigner_emitsSignerAddedEvent`                                         | Emits `SignerAdded` event.                      | Yes        | Yes         |
| `test_addSigner_revertsIfSignerAlreadyActive`                                  | Add an already active signer.                   | No         | Yes         |
| `test_addSigner_revertsIfSignerWasPreviouslyActive`                            | Add a previously active signer.                 | No         | Yes         |
| `test_removeSigner_revertsIfCalledByNonZoneManagerRole`                        | Remove signer without authorization.            | Yes        | Yes         |
| `test_removeSigner_revertsIfSignerNotActive`                                   | Remove a signer that is not active.             | No         | Yes         |
| `test_removeSigner_emitsSignerRemovedEvent`                                    | Emits `SignerRemoved` event.                    | Yes        | Yes         |
| `test_updateAPIEndpoint_revertsIfCalledByNonZoneManagerRole`                   | Update API endpoint without authorization.      | No         | Yes         |
| `test_updateAPIEndpoint_updatesAPIEndpointIfCalledByZoneManagerRole`           | Update API endpoint with authorization.         | Yes        | Yes         |
| `test_updateDocumentationURI_revertsIfCalledByNonZoneManagerRole`              | Update documentation URI without authorization. | No         | Yes         |
| `test_updateDocumentationURI_updatesDocumentationURIIfCalledByZoneManagerRole` | Update documentation URI with authorization.    | Yes        | Yes         |

Operational function tests:

| Test name                                                                   | Description                                         | Happy Case | Implemented |
| --------------------------------------------------------------------------- | --------------------------------------------------- | ---------- | ----------- |
| `test_getSeaportMetadata`                                                   | Retrieve metadata describing the Zone.              | Yes        | Yes         |
| `test_sip7Information`                                                      | Retrieve SIP-7 specific information.                | Yes        | Yes         |
| `test_supportsInterface`                                                    | ERC165 support.                                     | Yes        | Yes         |
| `test_authorizeOrder_revertsIfEmptyExtraData`                               | Authorize order with empty `extraData`.             | No         | Yes         |
| `test_authorizeOrder_revertsIfExtraDataLengthIsLessThan93`                  | Authorize order with unexpected `extraData` length. | No         | Yes         |
| `test_authorizeOrder_revertsIfExtraDataVersionIsNotSupported`               | Authorize order with unexpected SIP-6 version byte. | No         | Yes         |
| `test_authorizeOrder_revertsIfSignatureHasExpired`                          | Authorize order with an expired signature.          | No         | Yes         |
| `test_authorizeOrder_revertsIfActualFulfillerDoesNotMatchExpectedFulfiller` | Authorize order with unexpected fufiller.           | No         | Yes         |
| `test_authorizeOrder_revertsIfSignerIsNotActive`                            | Authorize order with inactive signer.               | No         | Yes         |
| `test_authorizeOrder_returnsMagicValueOnSuccessfulValidation`               | Authorize order successfully.                       | Yes        | Yes         |
| `test_validateOrder_revertsIfContextIsEmpty`                                | Validate order with an empty context.               | No         | Yes         |
| `test_validateOrder_returnsMagicValueOnSuccessfulValidation`                | Validate order successfully.                        | Yes        | Yes         |

Internal operational function tests:

| Test name                                                                                        | Description                                                                                     | Happy Case | Implemented |
| ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- | ---------- | ----------- |
| `test_domainSeparator_returnsCachedDomainSeparatorWhenChainIDMatchesValueSetOnDeployment`        | Domain separator basic test.                                                                    | Yes        | Yes         |
| `test_domainSeparator_returnsUpdatedDomainSeparatorIfChainIDIsDifferentFromValueSetOnDeployment` | Domain separator changes when chain ID changes.                                                 | Yes        | Yes         |
| `test_deriveDomainSeparator_returnsDomainSeparatorForChainID`                                    | Domain separator derivation.                                                                    | Yes        | Yes         |
| `test_getSupportedSubstandards`                                                                  | Retrieve Zone's supported substandards.                                                         | Yes        | Yes         |
| `test_deriveSignedOrderHash_returnsHashOfSignedOrder`                                            | Signed order hash derivation.                                                                   | Yes        | Yes         |
| `test_validateSubstandards_revertsIfEmptyContext`                                                | Empty context without substandards.                                                             | No         | Yes         |
| `test_validateSubstandards_beforeHookSubstandard1`                                               | Context with substandard 1 in before hook.                                                      | Yes        | Yes         |
| `test_validateSubstandards_afterHookSubstandard1`                                                | Context with substandard 1 in after hook.                                                       | Yes        | Yes         |
| `test_validateSubstandards_beforeHookSubstandard3`                                               | Context with substandard 3 in before hook.                                                      | Yes        | Yes         |
| `test_validateSubstandards_afterHookSubstandard3`                                                | Context with substandard 3 in after hook.                                                       | Yes        | Yes         |
| `test_validateSubstandards_beforeHookSubstandard4`                                               | Context with substandard 4 in before hook.                                                      | Yes        | Yes         |
| `test_validateSubstandards_afterHookSubstandard4`                                                | Context with substandard 4 in after hook.                                                       | Yes        | Yes         |
| `test_validateSubstandards_beforeHookSubstandard6`                                               | Context with substandard 6 in before hook.                                                      | Yes        | Yes         |
| `test_validateSubstandards_afterHookSubstandard6`                                                | Context with substandard 6 in after hook.                                                       | Yes        | Yes         |
| `test_validateSubstandards_beforeHookMultipleSubstandardsInCorrectOrder`                         | Context with multiple substandards in before hook.                                              | Yes        | Yes         |
| `test_validateSubstandards_afterHookMultipleSubstandardsInCorrectOrder`                          | Context with multiple substandards in after hook.                                               | Yes        | Yes         |
| `test_validateSubstandards_beforeHookSubstandards3Then6`                                         | Context with substandards 3 and 6, but not 4 in before hook.                                    | Yes        | Yes         |
| `test_validateSubstandards_beforeHookSubstandards3Then6`                                         | Context with substandards 3 and 6, but not 4 in after hook.                                     | Yes        | Yes         |
| `test_validateSubstandards_beforeHookAllSubstandards`                                            | Context with all substandards in before hook.                                                   | Yes        | Yes         |
| `test_validateSubstandards_afterHookAllSubstandards`                                             | Context with all substandards in after hook.                                                    | Yes        | Yes         |
| `test_validateSubstandards_revertsOnMultipleSubstandardsInIncorrectOrder`                        | Context with multiple substandards out of order.                                                | No         | Yes         |
| `test_validateSubstandard1_returnsZeroLengthIfNotSubstandard1`                                   | Substandard 1 validation skips when version byte is not 1.                                      | Yes        | Yes         |
| `test_validateSubstandard1_revertsIfContextLengthIsInvalid`                                      | Substandard 1 validation with invalid data.                                                     | No         | Yes         |
| `test_validateSubstandard1_revertsIfFirstReceivedItemIdentifierNotEqualToIdentifierInContext`    | Substandard 1 validation when first received item identifier doesn't match expected identifier. | No         | Yes         |
| `test_validateSubstandard1_beforeHookReturns33OnSuccess`                                         | Substandard 1 validation when first received item identifier matches expected identifier.       | Yes        | Yes         |
| `test_validateSubstandard1_afterHookReturns33OnSuccess`                                          | Substandard 1 success in after hook.                                                            | Yes        | Yes         |
| `test_validateSubstandard3_returnsZeroLengthIfNotSubstandard3`                                   | Substandard 3 validation skips when version byte is not 3.                                      | Yes        | Yes         |
| `test_validateSubstandard3_revertsIfContextLengthIsInvalid`                                      | Substandard 3 validation with invalid data.                                                     | No         | Yes         |
| `test_validateSubstandard3_revertsIfDerivedReceivedItemsHashNotEqualToHashInContext`             | Substandard 3 validation when derived hash doesn't match expected hash.                         | No         | Yes         |
| `test_validateSubstandard3_beforeHookReturns33OnSuccess`                                         | Substandard 3 validation when derived hash matches expected hash.                               | Yes        | Yes         |
| `test_validateSubstandard3_afterHookReturns33OnSuccess`                                          | Substandard 3 success in after hook.                                                            | Yes        | Yes         |
| `test_validateSubstandard4_returnsZeroLengthIfNotSubstandard4`                                   | Substandard 4 validation skips when version byte is not 4.                                      | Yes        | Yes         |
| `test_validateSubstandard4_revertsIfContextLengthIsInvalid`                                      | Substandard 4 validation with invalid data.                                                     | No         | Yes         |
| `test_validateSubstandard4_revertsIfExpectedOrderHashesAreNotPresent`                            | Substandard 4 validation when required order hashes are not present.                            | No         | Yes         |
| `test_validateSubstandard4_beforeHookReturnsLengthOfSubstandardSegmentOnSuccess`                 | Substandard 4 success in before hook.                                                           | Yes        | Yes         |
| `test_validateSubstandard4_afterHookReturnsLengthOfSubstandardSegmentOnSuccess`                  | Substandard 4 validation when required order hashes are present.                                | Yes        | Yes         |
| `test_validateSubstandard6_returnsZeroLengthIfNotSubstandard6`                                   | Substandard 6 validation skips when version byte is not 6.                                      | Yes        | Yes         |
| `test_validateSubstandard6_revertsIfContextLengthIsInvalid`                                      | Substandard 6 validation with invalid data.                                                     | No         | Yes         |
| `test_validateSubstandard6_revertsIfDerivedReceivedItemsHashesIsNotEqualToHashesInContext`       | Substandard 6 validation when derived hash doesn't match expected hash.                         | No         | Yes         |
| `test_validateSubstandard6_beforeHookReturnsLengthOfSubstandardSegmentOnSuccess`                 | Substandard 6 validation when derived hash matches expected hash.                               | Yes        | Yes         |
| `test_validateSubstandard6_afterHookReturnsLengthOfSubstandardSegmentOnSuccess`                  | Substandard 6 success in after hook.                                                            | Yes        | Yes         |
| `test_deriveReceivedItemsHash_returnsHashIfNoReceivedItems`                                      | Received items derivation with not items.                                                       | Yes        | Yes         |
| `test_deriveReceivedItemsHash_returnsHashForValidReceivedItems`                                  | Received items derivation with some items.                                                      | Yes        | Yes         |
| `test_deriveReceivedItemsHash_returnsHashForReceivedItemWithAVeryLargeAmount`                    | Received items derivation with scaling factor forcing `> uint256` intermediate calcualtions.    | Yes        | Yes         |
| `test_bytes32ArrayIncludes_returnsFalseIfSourceArrayIsSmallerThanValuesArray`                    | `byte32` array inclusion check when more values than in source.                                 | Yes        | Yes         |
| `test_bytes32ArrayIncludes_returnsFalseIfSourceArrayDoesNotIncludeValuesArray`                   | `byte32` array inclusion check when values are not present in source.                           | Yes        | Yes         |
| `test_bytes32ArrayIncludes_returnsTrueIfSourceArrayEqualsValuesArray`                            | `byte32` array inclusion check when source and values are identical.                            | Yes        | Yes         |
| `test_bytes32ArrayIncludes_returnsTrueIfValuesArrayIsASubsetOfSourceArray`                       | `byte32` array inclusion check when values are present in source.                               | Yes        | Yes         |

Integration tests:

All of these tests are in [test/trading/seaport16/ImmutableSeaportSignedZoneV3Integration.t.sol](../../../ImmutableSeaportSignedZoneV3Integration.t.sol).

| Test name                                            | Description                     | Happy Case | Implemented |
| ---------------------------------------------------- | ------------------------------- | ---------- | ----------- |
| `test_fulfillAdvancedOrder_withCompleteFulfilment`   | Full fulfilment.                | Yes        | Yes         |
| `test_fulfillAdvancedOrder_withPartialFill`          | Partial fulfilment.             | Yes        | Yes         |
| `test_fulfillAdvancedOrder_withMultiplePartialFills` | Sequential partial fulfilments. | Yes        | Yes         |
| `test_fulfillAdvancedOrder_withOverfilling`          | Over fulfilment.                | Yes        | Yes         |
