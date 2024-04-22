# Immutable Signed Zone (v2)

The Immutable Signed Zone contract is a [Seaport Zone](https://docs.opensea.io/docs/seaport-hooks#zone-hooks) that implements [SIP-7 (Interface for Server-Signed Orders)](https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md) with support for [substandards](https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md#substandards) 3, 4 and 6.

This zone is used by Immutable to enable:

* Enforcement of protocol, royalty and ecosystem fees
* Off-chain order cancellation

# Status

Contract threat models and audits:

| Description                     | Date | Version Audited | Link to Report |
| ------------------------------- | ---- | --------------- | -------------- |
| Not audited and no threat model | -    | -               | -              |

## ImmutableSignedZoneV2

| Location                | Date         | Version Deployed | Address |
| ----------------------- | ------------ | ---------------- | ------- |
| Immutable zkEVM Testnet | Not deployed | -                | -       |
| Immutable zkEVM Mainnet | Not deployed | -                | -       |

## Architecture

The trading system on the Immutable platform is shown in the diagram below.

```mermaid
flowchart LR
  client[Client] <-- 1. POST .../fulfillment-data ---> ob[Immutable Off-Chain\nOrderbook]
  client -- 2. fulfillAdvancedOrder ---> seaport[ImmutableSeaport.sol]
  seaport -- 3a. transferFrom --> erc20[IERC20.sol]
  seaport -- 3b. transferFrom --> erc721[IERC721.sol]
  seaport -- 3c. safeTransferFrom --> erc1155[IERC1155.sol]
  seaport -- 4. validateOrder --> Zone
  subgraph Zone
    direction TB
    zone[ImmutableSignedZoneV2.sol] --> AccessControlEnumerable.sol
  end
```

The sequence of events is as follows:

1. The client makes a HTTP `POST .../fulfillment-data` request to the Immutable Orderbook, which will construct and sign an `extraData` payload to return to the client
2. The client calls `fulfillAdvancedOrder` or `fulfillAvailableAdavancedOrders` on `ImmutableSeaport.sol` to fulfill an order
3. `ImmutableSeaport.sol` executes the fufilment by transferring items between parties
4. `ImmutableSeaport.sol` calls `validateOrder` on `ImmutableSignedZoneV2.sol`, passing it the fulfilment execution details as well as the `extraData` parameter
   1. `ImmutableSignedZoneV2.sol` validates the fulfilment execution details using the `extraData` payload, reverting if expectations are not met