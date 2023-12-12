# Immutable Wallet Contracts

This is a fork of of Sequence's [wallet-contracts repo](https://github.com/0xsequence/wallet-contracts).

## Immutable Changes

The following changes have been made:

- The minimal wallet proxy contract (bytecode of which is in
  src/contracts/Wallet.sol) now supports a function `PROXY_getImplementation` to
  return the address of the implementation contract pointed to by the proxy
  contract.
- The interface for the `PROXY_getImplementation` function is defined in
  src/contracts/IWalletProxy.sol.
- The source code for the new bytecode is in `src/contracts/WalletProxy.yul`.
- All references to the bytecode of the proxy now use the definition in
  `src/contracts/Wallet.sol` (rather than having their own definition).
- `StartupWalletImpl.sol` is a minimal initial implementation that updates the
  implementation address and then delegate calls to the wallet implementation.
  This contract determines the latest wallet implementation contract to use by
  contacting the new contract `LatestWalletImplLocator.sol`.
- `MainModuleDynamicAuth.sol` which uses `ModuleAuth.sol` is a type of wallet
  implementation that initially does authentication by checking that the
  contract address matches being generated using the image hash, the factory
  contract, and the proxy start-up bytes (which include the address of the
  wallet implementation contract: the instance of `StartupWalletImpl`). The
  image hash is stored and subsequence transactions verify by comparing the
  calculated image hash with the stored image hash.
- Tests for the new wallet factory features have been included in
  `ImmutableFactory.spec.ts`.
- Tests for the startup and dynamic authentication have been included in
  `ImmutableStartup.spec.ts`.
- Tests for the Immutable deployment have been included in
  `ImmutableDeployment.spec.ts`.

## Security Review

`@imtbl/wallet-contracts` has been audited by three independant parties

- [Consensys Diligence](./audits/Consensys_Diligence.md) - May 2020
- [Quantstamp - initial audit](./audits/Quantstamp_Arcadeum_Report_Final.pdf) - July 2020
- [Quantstamp - audit of new capability, nested Sequence signers](./audits/sequence_quantstamp_audit_feb_2021.pdf) - Feb 2021
- [Halborm - audit of security improvements and customisations for Immutable environment](./audits/202309_Halborn_Final.pdf) - Sept 2023. 
See [background information for this audit](./audits/202309_audit_background.md). 

## Dev env & release

This repository is configured as a yarn workspace, and has multiple pacakge.json
files. Specifically, we have the root ./package.json for the development
environment, contract compilation and testing. Contract source code and
distribution files are packaged in "src/package.json".

To release a new version, make sure to bump the version, tag it, and run `yarn
release`. The `release` command will publish the `@imtbl/wallet-contracts`
package in the "src/" folder, separate from the root package.

## Contribution

We aim to build robust and feature-rich standards to help all developers onboard
and build their projects on Immuable zkEVM, and we welcome any and all feedback
and contributions to this repository! See our [contribution
guideline](CONTRIBUTING.md) for more details on opening Github issues, pull
requests requesting features, minor security vulnerabilities and providing
general feedback.

## Disclaimers

These contracts are in an experimental stage and are subject to change without
notice. The code must still be formally audited or reviewed and may have
security vulnerabilities. Do not use it in production. We take no responsibility
for your implementation decisions and any security problems you might
experience.

We will audit these contracts before our mainnet launch.

## Security

Please see our [security.md](security.md)  page for information on how to report security issues.

## License

Immutable zkEVM Contracts are released under the Apache-2.0 license. See
[LICENSE.md](LICENSE.md) for more details.
