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

1. Installing Echidna
   ```bash
   # Install using the latest master branch
   pip install echidna-test
   ```

2. Install Foundry (for invariant tests)
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. Install dependencies
   ```bash
   forge install
   ```

## Running the Tests

### Echidna Fuzzing
```bash
echidna-test contracts/test/ERC721PsiV2.Echidna.sol \
  --contract ERC721PsiV2Echidna \
  --config echidna.config.yaml
```

### Foundry Invariant Tests
```bash
forge test --match-contract ERC721PsiV2InvariantTest -vvv
```

## Test Configuration

### Echidna Configuration (`echidna.config.yaml`)
```yaml
testMode: assertion
testLimit: 50000
corpusDir: corpus
coverage: true
seqLen: 100
shrinkLimit: 5000
prefix: "echidna_"
```

### Foundry Configuration (`foundry.toml`)
```toml
[profile.default]
src = 'contracts'
out = 'out'
libs = ['lib']
solc = "0.8.19"
optimizer = true
optimizer_runs = 200

[profile.default.fuzz]
runs = 1000
```

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
