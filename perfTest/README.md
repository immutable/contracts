# Gas / Performance test

To run these tests:

```
forge test -C perfTest --match-path "./perfTest/**" -vvv --block-gas-limit 1000000000000
```

To run tests for just one contract do something similar to:

```
forge test -C perfTest --match-path "./perfTest/**/ImmutableERC721V2ByQuantityPerfPrefill.t.sol" -vvv --block-gas-limit 1000000000000

```