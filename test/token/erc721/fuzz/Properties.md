# ERC721PsiV2 Fuzzing Properties

| Property ID | Description | Tested | Passed | Test Function |
|------------|-------------|---------|---------|---------------|
| **Core Invariants** |
| CORE-01 | Total supply matches minted tokens | ✅ | ✅ | `echidna_total_supply_matches()` |
| CORE-02 | Balance consistency across all accounts | ✅ | ✅ | `echidna_balance_consistency()` |
| CORE-03 | Balance sum matches total supply | ✅ | ✅ | `echidna_balance_sum_property()` |
| CORE-04 | All minted tokens have valid owners | ✅ | ✅ | `echidna_minted_tokens_have_owner()` |
| CORE-05 | Burned tokens have no owners | ✅ | ✅ | `echidna_burned_tokens_have_no_owner()` |
| CORE-06 | Non-existent tokens revert ownership checks | ✅ | ✅ | `echidna_nonexistent_ownership1()` |
| CORE-07 | Non-existent tokens revert ownership checks | ✅ | ✅ | `echidna_nonexistent_ownership2()` |
| **Batch Operations** |
| BATCH-01 | Group operations maintain consistency | ✅ | ✅ | `echidna_group_operations_sequence()` |
| BATCH-02 | Group occupancy limits respected | ✅ | ✅ | `echidna_group_occupancy()` |
| BATCH-03 | Group boundary operations work correctly | ✅ | ✅ | `echidna_group_boundary_sequence()` |
| BATCH-04 | Cross-group operations maintain consistency | ✅ | ✅ | `echidna_cross_group_operations()` |
| **Boundary Testing** |
| BOUND-01 | Minting sequence respects boundaries | ✅ | ✅ | `echidna_boundary_minting_sequence()` |
| BOUND-02 | Token ID boundary checks work | ✅ | ✅ | `echidna_mint_boundary_check()` |
| BOUND-03 | Quantity range validation works | ✅ | ✅ | `echidna_mint_quantity_range()` |
| BOUND-04 | Max token ID overflow protection | ✅ | ✅ | `echidna_max_token_id_overflow()` |
| BOUND-05 | 2^128 threshold is respected | ✅ | ✅ | `echidna_mint_threshold_respected()` |
| **Transfer & Approval Logic** |
| TRANS-01 | Complex transfer sequences work | ✅ | ✅ | `echidna_complex_transfer_sequence()` |
| TRANS-02 | Ownership updates correctly | ✅ | ✅ | `echidna_transfer_ownership_updates()` |
| TRANS-03 | Approval consistency maintained | ✅ | ✅ | `echidna_approval_consistency()` |
| TRANS-04 | Approval clearing works | ✅ | ✅ | `echidna_approval_clearing()` |
| **Security Checks** |
| SEC-01 | Reentrancy protection works | ✅ | ✅ | `echidna_reentrancy_protection()` |
| SEC-02 | Concurrent operations handled safely | ✅ | ✅ | `echidna_concurrent_operations()` |
| SEC-03 | Zero address operations prevented | ✅ | ✅ | `echidna_zero_address_protection()` |
| SEC-04 | Safe transfer callbacks work | ✅ | ✅ | `echidna_safe_transfer_callback()` |
| **Sequential Operations** |
| SEQ-01 | Token IDs are sequential | ✅ | ✅ | `echidna_sequential_token_ids()` |
| SEQ-02 | Token IDs are unique | ✅ | ✅ | `echidna_token_id_uniqueness()` |
| SEQ-03 | Supply sequence is valid | ✅ | ✅ | `echidna_total_supply_sequence()` |
| **Gas Optimization** |
| GAS-01 | Batch operations are gas efficient | ✅ | ✅ | `echidna_batch_operation_gas()` |
| **Basic Operations** |
| BASIC-01 | Minting by ID works | ✅ | ✅ | `echidna_mint_by_id()` |
| BASIC-02 | Minting by quantity works | ✅ | ✅ | `echidna_mint_by_quantity()` |
| BASIC-03 | Burning works | ✅ | ✅ | `echidna_burn()` |
| BASIC-04 | Unminted token burns fail | ✅ | ✅ | `echidna_burn_unminted()` |