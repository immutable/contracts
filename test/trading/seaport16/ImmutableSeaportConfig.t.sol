// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ImmutableSeaportBaseTest} from "./ImmutableSeaportBase.t.sol";
import {ImmutableSeaport} from "../../../contracts/trading/seaport16/ImmutableSeaport.sol";

contract ImmutableSeaportConfigTest is ImmutableSeaportBaseTest {
    function testEmitsAllowedZoneSetEvent() public {
        address zone = makeAddr("zone");
        bool allowed = true;

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit AllowedZoneSet(zone, allowed);
        immutableSeaport.setAllowedZone(zone, allowed);
    }

    function testRejectZeroAddressZone() public {
        vm.prank(owner);
        vm.expectRevert("ImmutableSeaport: zone is the zero address");
        immutableSeaport.setAllowedZone(address(0), true);
    }

    function testRejectAllowedZoneAlreadySetToTrue() public {
        address zone = makeAddr("zone");

        vm.prank(owner);
        immutableSeaport.setAllowedZone(zone, true);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ImmutableSeaport.AllowedZoneAlreadySet.selector, zone, true));
        immutableSeaport.setAllowedZone(zone, true);
    }

    function testRejectAllowedZoneAlreadySetToFalse() public {
        address zone = makeAddr("zone");

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ImmutableSeaport.AllowedZoneAlreadySet.selector, zone, false));
        immutableSeaport.setAllowedZone(zone, false);
    }
}
