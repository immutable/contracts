// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ImmutableSeaportBaseTest} from "./ImmutableSeaportBase.t.sol";

contract ImmutableSeaportConfigTest is ImmutableSeaportBaseTest {

    function testEmitsAllowedZoneSetEvent() public {
        address zone = makeAddr("zone");
        bool allowed = true;

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit AllowedZoneSet(zone, allowed);
        immutableSeaport.setAllowedZone(zone, allowed);
    }
}
