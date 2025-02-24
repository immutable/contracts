# ERC721PsiV2 Fuzzing Suite

## Overview

This fuzzing suite provides comprehensive invariant testing for the ERC721PsiV2 and ERC721PsiBurnableV2 contracts. The suite focuses on testing core functionality, edge cases, and specific features of the PSI implementation, including the unique minting mechanism, burning capabilities, and ownership management.

## Contents

The fuzzing suite tests the following core components:
- Token minting (both individual and batch)
- Token burning
- Ownership tracking
- Balance management
- Token ID sequencing
- Approval system

All properties tested can be found in `Properties.md`.

## Setup

1. Installing Echidna: [https://github.com/crytic/echidna](https://github.com/crytic/echidna)

## Running the Tests

### Echidna Fuzzing
```bash
echidna test/token/erc721/fuzz/ERC721PsiV2.Echidna.sol \
  --contract ERC721PsiV2Echidna \
  --config test/token/erc721/fuzz/echidna.config.yaml
```

### Foundry Invariant Tests
```bash
forge test --match-contract ERC721PsiV2InvariantTest -vvv
```

## Test Configuration

Echidna Configuration: [./echidna.config.yaml](echidna.config.yaml)

Foundry Configuration: [../../../../foundry.toml](../../../../foundry.toml)

## Scope

The following contracts are covered in this fuzzing suite:

```
contracts/token/erc721/erc721psi/ERC721PsiV2.sol
contracts/token/erc721/erc721psi/ERC721PsiBurnableV2.sol
```

Key features tested:
1. PSI-specific minting mechanism (2^128 threshold)
2. Batch minting functionality
3. Burning capabilities
4. Ownership and balance tracking
5. Token ID sequencing
6. Approval system

## Test Reports

- Echidna test results: `echidna-report.txt`
- Coverage information: `coverage.txt`
- Corpus directory: `corpus/`
- Foundry test results in console output

## Notes

- The fuzzing suite includes both positive and negative test cases
- Edge cases and boundary conditions are specifically targeted
- Gas optimization checks are included
- All tests are designed to be deterministic and reproducible
