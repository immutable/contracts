# Immutable Seaport
Immutable Seaport is a minor fork and extension of OpenSea's [Seaport](https://github.com/ProjectOpenSea/seaport) NFT settlement contract. The intension of the extension is to ensure that royalties and other platform fees (protocol, marketplace) are enforceable. This has been achieved with the use of a custom zone contract that implements [SIP7](https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md). 

## Seaport Fork Details
OpenSea split their Seaport implementation into 3 repositories:
- [seaport-types](https://github.com/ProjectOpenSea/seaport-types): This repo contains the core Seaport structs, enums, and interfaces for use in other Seaport repos.
- [seaport-core](https://github.com/ProjectOpenSea/seaport-core): This repo contains the core Seaport smart contracts (with no reference contracts, helpers, or tests) and is meant to facilitate building on Seaport without needing to grapple with long compile times or other complications.
- [seaport](https://github.com/ProjectOpenSea/seaport): This repo contains reference implementation contracts and testing utilities

### Seaport Types
No fork

### Seaport Core 
The function signatures in the `seaport-core` Consideration contract have [been updated](https://github.com/ProjectOpenSea/seaport-core/compare/main...immutable:seaport-core:1.5.0+im.1) to be `virtual` so that the `ImmutableSeaport` Consideration contract can add additional validation prior to calling the underlying `Consideration` implementation.

### Seaport
Immutable use [the fork](https://github.com/ProjectOpenSea/seaport/compare/main...immutable:seaport:1.5.0+im.1) to strictly pin the version of the upstream `seaport` contract implementations, which are currently on version 1.5. The fork also exposed testing utilities so that they can be used from the Immutable Seaport repository.

## Immutable Seaport Implementation
To ensure that the fees on an order meet the requirements of the Immutable ecosystem, all orders passed for consideration **must** be signed by an Immutable signer prior to fulfilment. This is achieved through the implementation of a SIP7 zone contract and by extending seaport consideration methods to ensure all fulfillments are validated by said zone.

### Extension to Seaport Consideration
The extension applies to all methods that can be used for order fulfilment and is always fundamentally the same; the order / orders being passed for fulfilment must be either `PARTIAL_RESTRICTED` or `FULL_RESTRICTED` and they must reference an allowed zone.

### Immutable Signed Zone
The [Immutable Signed Zone](https://github.com/immutable/immutable-seaport/blob/main/contracts/zones/ImmutableSignedZone.sol) is an implementation of the SIP-7 specification with sub-standards 3 and 4.

The `zone` of an order is a mandatory (in the case of `Immutable Seaport`) secondary account attached to the order with two additional privileges:
- The zone may cancel orders where it is named as the zone by calling `cancel`. (Note that offerers can also cancel their own orders, either individually or for all orders signed with their current counter at once by calling `incrementCounter`).
- "Restricted" orders (as specified by the order type) can be executed by anyone but must be approved by the zone indicated by a call to `validateOrder` on the zone.

The critical piece for the Immutable Seaport implementation is that all order executions make a call to `validateOrder` on the `Immutable Signed Zone`. If this check fails, the order will not be fulfilled.

## Other Contracts
We use some other contracts from the seaport ecosystem. These are unmodified and just reference the OpenSea upstream. These include:
- ReadOnlyOrderValidator
- SeaportValidator
- SeaportValidatorHelper
- ConduitController
