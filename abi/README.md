# Typescript ABIs

The `contracts` repo exports Typescript ABIs for customers to generate their own contract clients using modern libraries such as `abitype`, `viem` and `wagmi`, for interacting with deployed preset contracts.

## Adding a new Typescript ABI

Typescript ABIs are generated using `@wagmi/cli` and `foundry` build files:

- `@wagmi/cli` configuration can be found in file `wagmi.config.ts`
- `foundry` build files are available in this repo once built at folder `foundry-out`

To add a new Typescript ABI:

- Ensure the JSON ABI is available in folder `foundry-out`
- Update the configuration in `wagmi.config.ts` to add the ABI to the `contracts` array
- Run command `yarn wagmi generate` from the root of the folder
- Ensure the new Typescript ABI is available in `abi/generated.ts`
- Update `abi/index.ts` to rename and export Typescript ABI

The next published version will contain the new Typescript ABI.
