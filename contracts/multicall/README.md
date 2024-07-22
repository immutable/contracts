# GuardedMulticaller

The GuardedMulticaller contract provides functionality to call multiple functions across different target contracts, the function signatures are validated to ensure they are permitted. Currently one of the use cases we have is in the Primary Sales flow, the GuardedMulticaller executes `transferFrom()` and `safeMint()` functions on different target contracts in a single transaction. 

### Features

- Signature validation: Only approved signers can authorise the `execute` on the multicall contract.
- Function Permits: Security to prevent execution of unauthorised targets and functions.
- Expiry: Ability to set an expiry for the multicall.
- References: Map multicall executions to a reference string to be used by the application.

# Status

Contract audits and threat models:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| External audit            | Sept 26, 2023     | --- | [202309-external-audit-multicaller](../../audits/multicall/202309-external-audit-multicaller.pdf) |


# Architecture

The architecture of the GuardedMulticaller system is shown below. 

![GuardedMulticaller Architecture](../../audits/multicall/202309-threat-model-multicaller/architecture.png)
