# @imtbl/contracts — TypeScript surface

Published entry: [`index.ts`](./index.ts) → `dist/` via `tsc` (see root [`package.json`](../package.json) `exports`).

## Layout

| File | Purpose |
|------|---------|
| [`abis.ts`](./abis.ts) | Hand-maintained ABI fragments for preset contracts (PascalCase keys, same names as v2) |
| [`addresses.ts`](./addresses.ts) | Deployed addresses by chain (mainnet, testnet, etc.) |
| [`index.ts`](./index.ts) | Re-exports `abis` and `addresses` |

## Build

From the repository root:

```bash
yarn build
```

Solidity compilation and tests use Foundry (`forge build`, `forge test`). When adding or changing preset ABIs, update `abis.ts` and run `yarn build`.
