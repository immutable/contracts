// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
// solhint-disable not-rely-on-time

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {GemGame, Unauthorized, ContractPaused} from "../../../contracts/games/gems/GemGame.sol";

contract GemGameTest is Test {
    event GemEarned(address indexed account, uint256 timestamp);

    GemGame private _gemGame;

    function setUp() public {
        _gemGame = new GemGame(address(this), address(this), address(this));
    }

    function testEarnGemEmitsGemEarnedEvent() public {
        vm.expectEmit(true, true, false, false);
        emit GemEarned(address(this), block.timestamp);
        _gemGame.earnGem();
    }

    function testEarnGemContractPausedReverts() public {
        // pause the contract
        _gemGame.pause();

        // attempt to earn a gem
        vm.expectRevert(ContractPaused.selector);
        _gemGame.earnGem();
    }

    function testPausePausesContract() public {
        // pause the contract
        _gemGame.pause();

        assertEq(_gemGame.paused(), true, "GemGame should be paused");
    }

    function testPauseWithoutPauseRoleReverts() public {
        // revoke the pause role
        _gemGame.revokeRole(keccak256("PAUSE"), address(this));

        // attempt to pause
        vm.expectRevert(Unauthorized.selector);
        _gemGame.pause();
    }

    function testUnpauseUnpausesContract() public {
        // pause the contract
        _gemGame.pause();

        // unpause the contract
        _gemGame.unpause();

        assertEq(_gemGame.paused(), false, "GemGame should be unpaused");
    }

    function testUnpauseWithoutPauseRoleReverts() public {
        // revoke the unpause role
        _gemGame.revokeRole(keccak256("UNPAUSE"), address(this));

        // attempt to unpause
        vm.expectRevert(Unauthorized.selector);
        _gemGame.unpause();
    }
}
