// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2
// solhint-disable compiler-version
pragma solidity ^0.8.24;

import {Consideration} from "seaport-core-16/src/lib/Consideration.sol";
import {AdvancedOrder, BasicOrderParameters, CriteriaResolver, Execution, Fulfillment, FulfillmentComponent, Order} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {OrderType} from "seaport-types-16/src/lib/ConsiderationEnums.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ImmutableSeaportEvents} from "./interfaces/ImmutableSeaportEvents.sol";

/**
 * @title ImmutableSeaport
 * @custom:version 1.6
 * @notice Seaport is a generalized native token/ERC20/ERC721/ERC1155
 *         marketplace with lightweight methods for common routes as well as
 *         more flexible methods for composing advanced orders or groups of
 *         orders. Each order contains an arbitrary number of items that may be
 *         spent (the "offer") along with an arbitrary number of items that must
 *         be received back by the indicated recipients (the "consideration").
 */
contract ImmutableSeaport is Consideration, Ownable, ImmutableSeaportEvents {
    // Mapping to store valid ImmutableZones - this allows for multiple Zones
    // to be active at the same time, and can be expired or added on demand.
    // solhint-disable-next-line named-parameters-mapping
    mapping(address => bool) public allowedZones;

    error OrderNotRestricted(uint8 orderType);
    error AllowedZoneAlreadySet(address zone);
    error InvalidZone(address zone);

    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     * @param owner             The address of the owner of this contract. Specified in the
     *                          constructor to be CREATE2 / CREATE3 compatible.
     */
    constructor(address conduitController, address owner) Consideration(conduitController) Ownable() {
        require(owner != address(0), "ImmutableSeaport: owner is the zero address");
        // Transfer ownership to the address specified in the constructor
        _transferOwnership(owner);
    }

    /**
     * @dev Set the validity of a zone for use during fulfillment.
     */
    function setAllowedZone(address zone, bool allowed) external onlyOwner {
        require(zone != address(0), "ImmutableSeaport: zone is the zero address");

        if (allowedZones[zone] == allowed) {
            revert AllowedZoneAlreadySet(zone);
        }

        allowedZones[zone] = allowed;
        emit AllowedZoneSet(zone, allowed);
    }

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure override returns (string memory) {
        // Return the name of the contract.
        return "ImmutableSeaport";
    }

    /**
     * @dev Internal pure function to retrieve the name of this contract as a
     *      string that will be used to derive the name hash in the constructor.
     *
     * @return The name of this contract as a string.
     */
    // slither-disable-next-line dead-code
    function _nameString() internal pure override returns (string memory) {
        // Return the name of the contract.
        return "ImmutableSeaport";
    }

    /**
     * @dev Helper function to revert any basic order that has an invalid zone.
     *
     * @param parameters The basic order parameters.
     */
    function _rejectBasicOrderIfZoneInvalid(BasicOrderParameters calldata parameters) internal view {
        // Basic order types (modulo 4): 0 = FULL_OPEN, 1 = PARTIAL_OPEN, 2 = FULL_RESTRICTED, 3 = PARTIAL_RESTRICTED. Only restricted orders (types 2 and 3) are allowed
        if (uint256(parameters.basicOrderType) % 4 != 2 && uint256(parameters.basicOrderType) % 4 != 3) {
            revert OrderNotRestricted(uint8(uint256(parameters.basicOrderType) % 4));
        }
        _rejectIfZoneInvalid(parameters.zone);
    }

    /**
     * @dev Helper function to revert any order that has an invalid zone.
     *
     * @param order The order.
     */
    function _rejectOrderIfZoneInvalid(Order memory order) internal view {
        if (
            order.parameters.orderType != OrderType.FULL_RESTRICTED &&
            order.parameters.orderType != OrderType.PARTIAL_RESTRICTED
        ) {
            revert OrderNotRestricted(uint8(order.parameters.orderType));
        }
        _rejectIfZoneInvalid(order.parameters.zone);
    }

    /**
     * @dev Helper function to revert any advanced order that has an invalid zone.
     *
     * @param advancedOrder The advanced order.
     */
    function _rejectAdvancedOrderIfZoneInvalid(AdvancedOrder memory advancedOrder) internal view {
        if (
            advancedOrder.parameters.orderType != OrderType.FULL_RESTRICTED &&
            advancedOrder.parameters.orderType != OrderType.PARTIAL_RESTRICTED
        ) {
            revert OrderNotRestricted(uint8(advancedOrder.parameters.orderType));
        }
        _rejectIfZoneInvalid(advancedOrder.parameters.zone);
    }

    /**
     * @dev Helper function to revert if the zone is not allowed.
     *
     * @param zone The zone to check.
     */
    function _rejectIfZoneInvalid(address zone) internal view {
        if (!allowedZones[zone]) {
            revert InvalidZone(zone);
        }
    }

    /**
     * @notice Fulfill an order offering an ERC20, ERC721, or ERC1155 item by
     *         supplying Ether (or other native tokens), ERC20 tokens, an ERC721
     *         item, or an ERC1155 item as consideration. Six permutations are
     *         supported: Native token to ERC721, Native token to ERC1155, ERC20
     *         to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and ERC1155 to
     *         ERC20 (with native tokens supplied as msg.value). For an order to
     *         be eligible for fulfillment via this method, it must contain a
     *         single offer item (though that item may have a greater amount if
     *         the item is not an ERC721). An arbitrary number of "additional
     *         recipients" may also be supplied which will each receive native
     *         tokens or ERC20 items from the fulfiller as consideration. Refer
     *         to the documentation for a more comprehensive summary of how to
     *         utilize this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` to receive those items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(
        BasicOrderParameters calldata parameters
    ) public payable virtual override returns (bool fulfilled) {
        _rejectBasicOrderIfZoneInvalid(parameters);

        return super.fulfillBasicOrder(parameters);
    }

    /**
     * @notice Fulfill an order offering an ERC20, ERC721, or ERC1155 item by
     *         supplying Ether (or other native tokens), ERC20 tokens, an ERC721
     *         item, or an ERC1155 item as consideration. Six permutations are
     *         supported: Native token to ERC721, Native token to ERC1155, ERC20
     *         to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and ERC1155 to
     *         ERC20 (with native tokens supplied as msg.value). For an order to
     *         be eligible for fulfillment via this method, it must contain a
     *         single offer item (though that item may have a greater amount if
     *         the item is not an ERC721). An arbitrary number of "additional
     *         recipients" may also be supplied which will each receive native
     *         tokens or ERC20 items from the fulfiller as consideration. Refer
     *         to the documentation for a more comprehensive summary of how to
     *         utilize this method and what orders are compatible with it. Note
     *         that this function costs less gas than `fulfillBasicOrder` due to
     *         the zero bytes in the function selector (0x00000000) which also
     *         results in earlier function dispatch.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` to receive those items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    // solhint-disable-next-line func-name-mixedcase
    function fulfillBasicOrder_efficient_6GL6yc(
        BasicOrderParameters calldata parameters
    ) public payable virtual override returns (bool fulfilled) {
        _rejectBasicOrderIfZoneInvalid(parameters);

        return super.fulfillBasicOrder_efficient_6GL6yc(parameters);
    }

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @custom:param order        The order to fulfill. Note that both the
     *                            offerer and the fulfiller must first approve
     *                            this contract (or the corresponding conduit if
     *                            indicated) to transfer any relevant tokens on
     *                            their behalf and that contracts must implement
     *                            `onERC1155Received` to receive ERC1155 tokens
     *                            as consideration.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used (and direct approvals set on
     *                            this contract).
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillOrder(
        /**
         * @custom:name order
         */
        Order calldata order,
        bytes32 fulfillerConduitKey
    ) public payable virtual override returns (bool fulfilled) {
        _rejectOrderIfZoneInvalid(order);

        return super.fulfillOrder(order, fulfillerConduitKey);
    }

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @custom:param advancedOrder     The order to fulfill along with the
     *                                 fraction of the order to attempt to fill.
     *                                 Note that both the offerer and the
     *                                 fulfiller must first approve this
     *                                 contract (or their conduit if indicated
     *                                 by the order) to transfer any relevant
     *                                 tokens on their behalf and that contracts
     *                                 must implement `onERC1155Received` to
     *                                 receive ERC1155 tokens as consideration.
     *                                 Also note that all offer and
     *                                 consideration components must have no
     *                                 remainder after multiplication of the
     *                                 respective amount with the supplied
     *                                 fraction for the partial fill to be
     *                                 considered valid.
     * @custom:param criteriaResolvers An array where each element contains a
     *                                 reference to a specific offer or
     *                                 consideration, a token identifier, and a
     *                                 proof that the supplied token identifier
     *                                 is contained in the merkle root held by
     *                                 the item in question's criteria element.
     *                                 Note that an empty criteria indicates
     *                                 that any (transferable) token identifier
     *                                 on the token in question is valid and
     *                                 that no associated proof needs to be
     *                                 supplied.
     * @param fulfillerConduitKey      A bytes32 value indicating what conduit,
     *                                 if any, to source the fulfiller's token
     *                                 approvals from. The zero hash signifies
     *                                 that no conduit should be used (and
     *                                 direct approvals set on this contract).
     * @param recipient                The intended recipient for all received
     *                                 items, with `address(0)` indicating that
     *                                 the caller should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        /**
         * @custom:name advancedOrder
         */
        AdvancedOrder calldata advancedOrder,
        /**
         * @custom:name criteriaResolvers
         */
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) public payable virtual override returns (bool fulfilled) {
        _rejectAdvancedOrderIfZoneInvalid(advancedOrder);

        return super.fulfillAdvancedOrder(advancedOrder, criteriaResolvers, fulfillerConduitKey, recipient);
    }

    /**
     * @notice Attempt to fill a group of orders, each with an arbitrary number
     *         of items for offer and consideration. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *         Note that this function does not support criteria-based orders or
     *         partial filling of orders (though filling the remainder of a
     *         partially-filled order is supported).
     *
     * @custom:param orders                    The orders to fulfill. Note that
     *                                         both the offerer and the
     *                                         fulfiller must first approve this
     *                                         contract (or the corresponding
     *                                         conduit if indicated) to transfer
     *                                         any relevant tokens on their
     *                                         behalf and that contracts must
     *                                         implement `onERC1155Received` to
     *                                         receive ERC1155 tokens as
     *                                         consideration.
     * @custom:param offerFulfillments         An array of FulfillmentComponent
     *                                         arrays indicating which offer
     *                                         items to attempt to aggregate
     *                                         when preparing executions. Note
     *                                         that any offer items not included
     *                                         as part of a fulfillment will be
     *                                         sent unaggregated to the caller.
     * @custom:param considerationFulfillments An array of FulfillmentComponent
     *                                         arrays indicating which
     *                                         consideration items to attempt to
     *                                         aggregate when preparing
     *                                         executions.
     * @param fulfillerConduitKey              A bytes32 value indicating what
     *                                         conduit, if any, to source the
     *                                         fulfiller's token approvals from.
     *                                         The zero hash signifies that no
     *                                         conduit should be used (and
     *                                         direct approvals set on this
     *                                         contract).
     * @param maximumFulfilled                 The maximum number of orders to
     *                                         fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableOrders(
        /**
         * @custom:name orders
         */
        Order[] calldata orders,
        /**
         * @custom:name offerFulfillments
         */
        FulfillmentComponent[][] calldata offerFulfillments,
        /**
         * @custom:name considerationFulfillments
         */
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        public
        payable
        virtual
        override
        returns (bool[] memory, /* availableOrders */ Execution[] memory /* executions */)
    {
        uint256 numberOfOrders = orders.length;
        for (uint256 i = 0; i < numberOfOrders; i++) {
            Order memory order = orders[i];
            _rejectOrderIfZoneInvalid(order);
        }

        return
            super.fulfillAvailableOrders(
                orders,
                offerFulfillments,
                considerationFulfillments,
                fulfillerConduitKey,
                maximumFulfilled
            );
    }

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @custom:param advancedOrders            The orders to fulfill along with
     *                                         the fraction of those orders to
     *                                         attempt to fill. Note that both
     *                                         the offerer and the fulfiller
     *                                         must first approve this contract
     *                                         (or their conduit if indicated by
     *                                         the order) to transfer any
     *                                         relevant tokens on their behalf
     *                                         and that contracts must implement
     *                                         `onERC1155Received` to receive
     *                                         ERC1155 tokens as consideration.
     *                                         Also note that all offer and
     *                                         consideration components must
     *                                         have no remainder after
     *                                         multiplication of the respective
     *                                         amount with the supplied fraction
     *                                         for an order's partial fill
     *                                         amount to be considered valid.
     * @custom:param criteriaResolvers         An array where each element
     *                                         contains a reference to a
     *                                         specific offer or consideration,
     *                                         a token identifier, and a proof
     *                                         that the supplied token
     *                                         identifier is contained in the
     *                                         merkle root held by the item in
     *                                         question's criteria element. Note
     *                                         that an empty criteria indicates
     *                                         that any (transferable) token
     *                                         identifier on the token in
     *                                         question is valid and that no
     *                                         associated proof needs to be
     *                                         supplied.
     * @custom:param offerFulfillments         An array of FulfillmentComponent
     *                                         arrays indicating which offer
     *                                         items to attempt to aggregate
     *                                         when preparing executions. Note
     *                                         that any offer items not included
     *                                         as part of a fulfillment will be
     *                                         sent unaggregated to the caller.
     * @custom:param considerationFulfillments An array of FulfillmentComponent
     *                                         arrays indicating which
     *                                         consideration items to attempt to
     *                                         aggregate when preparing
     *                                         executions.
     * @param fulfillerConduitKey              A bytes32 value indicating what
     *                                         conduit, if any, to source the
     *                                         fulfiller's token approvals from.
     *                                         The zero hash signifies that no
     *                                         conduit should be used (and
     *                                         direct approvals set on this
     *                                         contract).
     * @param recipient                        The intended recipient for all
     *                                         received items, with `address(0)`
     *                                         indicating that the caller should
     *                                         receive the offer items.
     * @param maximumFulfilled                 The maximum number of orders to
     *                                         fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders.
     */
    function fulfillAvailableAdvancedOrders(
        /**
         * @custom:name advancedOrders
         */
        AdvancedOrder[] calldata advancedOrders,
        /**
         * @custom:name criteriaResolvers
         */
        CriteriaResolver[] calldata criteriaResolvers,
        /**
         * @custom:name offerFulfillments
         */
        FulfillmentComponent[][] calldata offerFulfillments,
        /**
         * @custom:name considerationFulfillments
         */
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        public
        payable
        virtual
        override
        returns (bool[] memory, /* availableOrders */ Execution[] memory /* executions */)
    {
        uint256 numberOfAdvancedOrders = advancedOrders.length;
        for (uint256 i = 0; i < numberOfAdvancedOrders; i++) {
            AdvancedOrder memory advancedOrder = advancedOrders[i];
            _rejectAdvancedOrderIfZoneInvalid(advancedOrder);
        }

        return
            super.fulfillAvailableAdvancedOrders(
                advancedOrders,
                criteriaResolvers,
                offerFulfillments,
                considerationFulfillments,
                fulfillerConduitKey,
                recipient,
                maximumFulfilled
            );
    }

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with a set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported). Any unspent
     *         offer item amounts or native tokens will be transferred to the
     *         caller.
     *
     * @custom:param orders       The orders to match. Note that both the
     *                            offerer and fulfiller on each order must first
     *                            approve this contract (or their conduit if
     *                            indicated by the order) to transfer any
     *                            relevant tokens on their behalf and each
     *                            consideration recipient must implement
     *                            `onERC1155Received` to receive ERC1155 tokens.
     * @custom:param fulfillments An array of elements allocating offer
     *                            components to consideration components. Note
     *                            that each consideration component must be
     *                            fully met for the match operation to be valid,
     *                            and that any unspent offer items will be sent
     *                            unaggregated to the caller.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders. Note that unspent offer item amounts or native
     *                    tokens will not be reflected as part of this array.
     */
    function matchOrders(
        /**
         * @custom:name orders
         */
        Order[] calldata orders,
        /**
         * @custom:name fulfillments
         */
        Fulfillment[] calldata fulfillments
    ) public payable virtual override returns (Execution[] memory /* executions */) {
        uint256 numberOfOrders = orders.length;
        for (uint256 i = 0; i < numberOfOrders; i++) {
            Order memory order = orders[i];
            _rejectOrderIfZoneInvalid(order);
        }

        return super.matchOrders(orders, fulfillments);
    }

    /**
     * @notice Match an arbitrary number of full, partial, or contract orders,
     *         each with an arbitrary number of items for offer and
     *         consideration, supplying criteria resolvers containing specific
     *         token identifiers and associated proofs as well as fulfillments
     *         allocating offer components to consideration components. Any
     *         unspent offer item amounts will be transferred to the designated
     *         recipient (with the null address signifying to use the caller)
     *         and any unspent native tokens will be returned to the caller.
     *
     * @custom:param advancedOrders    The advanced orders to match. Note that
     *                                 both the offerer and fulfiller on each
     *                                 order must first approve this contract
     *                                 (or their conduit if indicated by the
     *                                 order) to transfer any relevant tokens on
     *                                 their behalf and each consideration
     *                                 recipient must implement
     *                                 `onERC1155Received` to receive ERC1155
     *                                 tokens. Also note that the offer and
     *                                 consideration components for each order
     *                                 must have no remainder after multiplying
     *                                 the respective amount with the supplied
     *                                 fraction for the group of partial fills
     *                                 to be considered valid.
     * @custom:param criteriaResolvers An array where each element contains a
     *                                 reference to a specific offer or
     *                                 consideration, a token identifier, and a
     *                                 proof that the supplied token identifier
     *                                 is contained in the merkle root held by
     *                                 the item in question's criteria element.
     *                                 Note that an empty criteria indicates
     *                                 that any (transferable) token identifier
     *                                 on the token in question is valid and
     *                                 that no associated proof needs to be
     *                                 supplied.
     * @custom:param fulfillments      An array of elements allocating offer
     *                                 components to consideration components.
     *                                 Note that each consideration component
     *                                 must be fully met for the match operation
     *                                 to be valid, and that any unspent offer
     *                                 items will be sent unaggregated to the
     *                                 designated recipient.
     * @param recipient                The intended recipient for all unspent
     *                                 offer item amounts, or the caller if the
     *                                 null address is supplied.
     *
     * @return executions An array of elements indicating the sequence of
     *                     transfers performed as part of matching the given
     *                     orders. Note that unspent offer item amounts or
     *                     native tokens will not be reflected as part of this
     *                     array.
     */
    function matchAdvancedOrders(
        /**
         * @custom:name advancedOrders
         */
        AdvancedOrder[] calldata advancedOrders,
        /**
         * @custom:name criteriaResolvers
         */
        CriteriaResolver[] calldata criteriaResolvers,
        /**
         * @custom:name fulfillments
         */
        Fulfillment[] calldata fulfillments,
        address recipient
    ) public payable virtual override returns (Execution[] memory /* executions */) {
        uint256 numberOfAdvancedOrders = advancedOrders.length;
        for (uint256 i = 0; i < numberOfAdvancedOrders; i++) {
            AdvancedOrder memory advancedOrder = advancedOrders[i];
            _rejectAdvancedOrderIfZoneInvalid(advancedOrder);
        }

        return super.matchAdvancedOrders(advancedOrders, criteriaResolvers, fulfillments, recipient);
    }
}
