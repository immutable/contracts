# Security Policy

Security vulnerabilities should be disclosed to the project maintainers through our public [immutable bug bounty program](https://bugcrowd.com/immutable-og) or email us at security@immutable.com.

## Security Patches

Security vulnerabilities will be patched as soon as responsibly possible, and published as an advisory on this repository and on the affected npm packages.

Projects that build on Immutable's contracts are encouraged to clearly state, in their source code and websites, how to be contacted about security issues in the event that a direct notification is considered necessary. We recommend including it in the NatSpec for the contract as `/// @custom:security-contact security@example.com`.

Additionally, we recommend installing the library through npm and setting up vulnerability alerts such as [Dependabot].

[Dependabot]: https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-supply-chain-security#what-is-dependabot

### Supported Versions

Security patches will be released for the latest minor of a given major release. For example, if an issue is found in versions >=1.1.0 and the latest is 1.8.0, the patch will be released only in version 1.8.1.

Only critical severity bug fixes will be backported to past major releases.

| Version | Critical security fixes | Other security fixes |
| ------- | ----------------------- | -------------------- |
| 0.x     | :white_check_mark:      | :white_check_mark:   |

Note as well that the Solidity language itself only guarantees security updates for the latest release.

## Legal

Smart contracts are a nascent techology and carry a high level of technical risk and uncertainty. Immutable's zkEVM Contracts are made available under the Apache-2.0 License, which disclaims all warranties in relation to the project and which limits the liability of those that contribute and maintain the project, including Immutable. In your use of this project, you are solely responsible for any use of Immutable zkEVM Contracts and you assume all risks associated with any such use. This Security Policy in no way evidences or represents an on-going duty by any contributor, including Immutable, to correct any flaws or alert you to all or any of the potential risks of utilizing the project.