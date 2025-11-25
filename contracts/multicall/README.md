# GuardedMulticaller2

The GuardedMulticaller2 is a signatured-based multi-call contract. It provides functionality to call multiple functions across different target contracts, the function signatures are validated to ensure they are permitted. In use cases such as crafting and Primary sales, the GuardedMulticaller2 executes mint, burn, or transfer functions on different target contracts in a single transaction. 

### Features

- Signature validation: Only approved signers can authorise the `execute` on the multicall contract.
- Expiry: Ability to set an expiry for the multicall.
- References: Map multicall executions to a reference string to be used by the application.

# Status

Contract audits and threat models:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| V2 Threat Model              |     | --- | [202408-threat-model-multicaller](../../audits/multicall/202408-threat-model-multicaller.md) |
| V1 Threat Model              | Sept 26, 2023     | --- | [202309-threat-model-multicaller](../../audits/multicall/202309-threat-model-multicaller.md) |
| V1 External audit            | Sept 26, 2023     | [e59b72a](https://github.com/immutable/contracts/blob/e59b72a69294bd6d5857a1e2d019044bbfb14632/contracts/multicall) | [202309-external-audit-multicaller](../../audits/multicall/202309-external-audit-multicaller.pdf) |


# Architecture

The architecture of the GuardedMulticaller system is shown below. 

![GuardedMulticaller Architecture](../../audits/multicall/202309-threat-model-multicaller/architecture.png)

> **Note:** GuardedMulticaller v1 has been removed. Only GuardedMulticaller2 is supported.
