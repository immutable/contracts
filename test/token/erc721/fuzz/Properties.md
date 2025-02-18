# ERC721PsiV2 Fuzzing Properties

| Property ID | Description | Tested | Passed | Test Function |
|------------|-------------|---------|---------|---------------|
| MINT-01 | Minting below 2^128 threshold uses correct token IDs | ✅ | ✅ | `echidna_mint_by_id()` |
| MINT-02 | Batch minting above 2^128 threshold uses correct token IDs | ✅ | ✅ | `echidna_mint_by_quantity()` |
| MINT-03 | Token IDs respect the 2^128 threshold boundary | ✅ | ✅ | `echidna_mint_threshold_respected()` |
| BURN-01 | Burned tokens have no valid owner | ✅ | ✅ | `echidna_burned_tokens_have_no_owner()` |
| BURN-02 | Cannot burn non-existent tokens | ✅ | ✅ | `echidna_burn()` |
| OWN-01 | All minted (non-burned) tokens have valid owners | ✅ | ✅ | `echidna_minted_tokens_have_owner()` |
| OWN-02 | Ownership updates correctly after transfers | ✅ | ✅ | `echidna_transfer_ownership_updates()` |
| OWN-03 | Token IDs are unique per owner | ✅ | ✅ | `echidna_token_id_uniqueness()` |
| SUPPLY-01 | Total supply matches minted minus burned tokens | ✅ | ✅ | `echidna_total_supply_matches()` |
| BAL-01 | User balances match their owned tokens | ✅ | ✅ | `echidna_balance_consistency()` |
| SEQ-01 | Token IDs are sequential within their ranges | ✅ | ✅ | `echidna_sequential_token_ids()` |
| APPR-01 | Approval system maintains consistency | ✅ | ✅ | `echidna_approval_consistency()` |

## Property Details

### Minting Properties

#### MINT-01: Minting Below Threshold
- Ensures tokens minted below 2^128 use correct ID assignment
- Verifies individual minting mechanism
- Test: `echidna_mint_by_id()`

#### MINT-02: Batch Minting Above Threshold
- Validates batch minting above 2^128 threshold
- Ensures correct sequential ID assignment
- Test: `echidna_mint_by_quantity()`

#### MINT-03: Threshold Boundary
- Verifies strict adherence to 2^128 threshold
- Prevents threshold violations
- Test: `echidna_mint_threshold_respected()`

### Burning Properties

#### BURN-01: Burned Token State
- Ensures burned tokens have no owner
- Verifies complete removal from ownership records
- Test: `echidna_burned_tokens_have_no_owner()`

#### BURN-02: Burn Validation
- Prevents burning of non-existent tokens
- Validates burn operation preconditions
- Test: `echidna_burn()`

### Ownership Properties

#### OWN-01: Token Ownership
- Validates all minted tokens have valid owners
- Prevents zero-address ownership
- Test: `echidna_minted_tokens_have_owner()`

#### OWN-02: Transfer Mechanics
- Ensures correct ownership updates after transfers
- Validates transfer mechanics
- Test: `echidna_transfer_ownership_updates()`

#### OWN-03: Token Uniqueness
- Prevents duplicate token IDs
- Ensures unique ownership records
- Test: `echidna_token_id_uniqueness()`

### Supply and Balance Properties

#### SUPPLY-01: Supply Tracking
- Validates total supply calculations
- Ensures consistency with mint/burn operations
- Test: `echidna_total_supply_matches()`

#### BAL-01: Balance Consistency
- Verifies user balance accuracy
- Ensures consistency with ownership records
- Test: `echidna_balance_consistency()`

### Sequential Properties

#### SEQ-01: Token ID Sequencing
- Validates sequential ID assignment
- Ensures proper ID ordering
- Test: `echidna_sequential_token_ids()`

### Approval Properties

#### APPR-01: Approval System
- Validates operator approval mechanics
- Ensures approval state consistency
- Test: `echidna_approval_consistency()`

## Test Coverage

All properties are tested using both:
1. Echidna fuzzing with 50,000 test runs
2. Foundry invariant testing with 1,000 runs per test

## Notes

- All tests passed successfully
- Coverage includes edge cases and boundary conditions
- Testing includes both positive and negative scenarios
- Properties verify core ERC721 functionality and PSI-specific features
