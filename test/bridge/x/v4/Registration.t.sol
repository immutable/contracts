// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Registration} from "../../../../contracts/bridge/x/v4/Registration.sol";
import {Test} from "forge-std/Test.sol";
import {DeployRegistrationV4Dev} from "../../../../script/DeployRegistrationV4Dev.s.sol";
import {MockCore} from "./MockCore.sol";

contract RegistrationTest is Test {
    MockCore public mockCore;
    Registration public registration;

    uint256 private MOCK_CORE_FUNDS = 5e18;

    function setUp() public {
        vm.startBroadcast();
        mockCore = new MockCore();
        registration = new Registration(payable(mockCore));
        vm.deal(payable(mockCore), MOCK_CORE_FUNDS);
        vm.stopBroadcast();
    }

    function testGetVersion() public {
        string memory version = registration.getVersion();
        assertTrue(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("4.0.1")));
    }

    function testCompleteWithdrawalAll_WhenUserIsRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        uint256 ethKey = 983301674259619813482344086789227297671214399350;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // arrange
        bytes memory regSig = abi.encodePacked(
            uint256(0x06f56e3e7392318ae672ff7d68d1b6c54a6f402019bd121dee9b8d8aa9658ab5), // r
            uint256(0x06c1b98af915c6c1f88ea15f22f2d4f4a7a20c5416cafca0538bf227469dc14a), // s
            uint256(0x02ec99c3c1d90d78dd77676a2505bbeba3cf9ecd1003d72c14949817d84625a4) // starkY
        );
        registration.imx().registerEthAddress(ethAdd, starkKey, regSig);
        // pre-checks
        assertTrue(registration.isRegistered(starkKey));

        // 0x2705737cd248ac819034b5de474c8f0368224f72a0fda9e031499d519992d9e (eth)
        uint256 assetType = 1103114524755001640548555873671808205895038091681120606634696969331999845790;
        uint256 ethExpectedBalance = 4e10;
        mockCore.addWithdrawalBalance(ethKey, assetType, ethExpectedBalance);
        uint256 ethWithdrawableBalance = registration.imx().getWithdrawalBalance(ethKey, assetType);
        assertEq(ethExpectedBalance, ethWithdrawableBalance);

        uint256 starkExpectedBalance = 3e10;
        mockCore.addWithdrawalBalance(starkKey, assetType, starkExpectedBalance);
        uint256 starkWithdrawableBalance = registration.imx().getWithdrawalBalance(starkKey, assetType);
        assertEq(starkExpectedBalance, starkWithdrawableBalance);
        //
        uint256 initialBalance = ethAdd.balance;
        //        // act
        registration.withdrawAll(ethKey, starkKey, assetType);
        //
        uint256 finalBalance = ethAdd.balance;
        uint256 expectedFinalBalance = initialBalance + ethExpectedBalance + starkExpectedBalance;
        assertEq(expectedFinalBalance, finalBalance);
    }

    function testShouldFailWithdrawalAll_WhenUserIsNotRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        uint256 ethKey = 983301674259619813482344086789227297671214399350;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // 0x2705737cd248ac819034b5de474c8f0368224f72a0fda9e031499d519992d9e (eth)
        uint256 assetType = 1103114524755001640548555873671808205895038091681120606634696969331999845790;

        uint256 ethExpectedBalance = 4e10;
        mockCore.addWithdrawalBalance(ethKey, assetType, ethExpectedBalance);
        uint256 ethWithdrawableBalance = registration.imx().getWithdrawalBalance(ethKey, assetType);
        assertEq(ethExpectedBalance, ethWithdrawableBalance);

        uint256 starkExpectedBalance = 3e10;
        mockCore.addWithdrawalBalance(starkKey, assetType, starkExpectedBalance);
        uint256 starkWithdrawableBalance = registration.imx().getWithdrawalBalance(starkKey, assetType);
        assertEq(starkExpectedBalance, starkWithdrawableBalance);

        address registeredEthAddress = registration.imx().getEthKey(starkKey);
        assertEq(address(0), registeredEthAddress);

        uint256 initialBalance = ethAdd.balance;
        vm.expectRevert("USER_UNREGISTERED");
        // act
        registration.withdrawAll(ethKey, starkKey, assetType);

        uint256 finalBalance = ethAdd.balance;
        assertEq(initialBalance, finalBalance);
    }

    function testCompleteWithdrawalV4_WhenUserIsNotRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        uint256 ethKey = 983301674259619813482344086789227297671214399350;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // 0x2705737cd248ac819034b5de474c8f0368224f72a0fda9e031499d519992d9e (eth)
        uint256 assetType = 1103114524755001640548555873671808205895038091681120606634696969331999845790;

        uint256 ethExpectedBalance = 4e10;
        mockCore.addWithdrawalBalance(ethKey, assetType, ethExpectedBalance);
        uint256 ethWithdrawableBalance = registration.imx().getWithdrawalBalance(ethKey, assetType);
        assertEq(ethExpectedBalance, ethWithdrawableBalance);

        uint256 starkExpectedBalance = 3e10;
        mockCore.addWithdrawalBalance(starkKey, assetType, starkExpectedBalance);
        uint256 starkWithdrawableBalance = registration.imx().getWithdrawalBalance(starkKey, assetType);
        assertEq(starkExpectedBalance, starkWithdrawableBalance);

        address registeredEthAddress = registration.imx().getEthKey(starkKey);
        assertEq(address(0), registeredEthAddress);

        uint256 initialBalance = ethAdd.balance;
        // act
        registration.imx().withdraw(ethKey, assetType);

        uint256 finalBalance = ethAdd.balance;
        assertEq(initialBalance + ethExpectedBalance, finalBalance);
    }

    function testRegisterAndCompleteWithdrawalAll_WhenUserIsNotRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        uint256 ethKey = 983301674259619813482344086789227297671214399350;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // 0x2705737cd248ac819034b5de474c8f0368224f72a0fda9e031499d519992d9e (eth)
        uint256 assetType = 1103114524755001640548555873671808205895038091681120606634696969331999845790;

        uint256 ethExpectedBalance = 4e10;
        mockCore.addWithdrawalBalance(ethKey, assetType, ethExpectedBalance);
        uint256 ethWithdrawableBalance = registration.imx().getWithdrawalBalance(ethKey, assetType);
        assertEq(ethExpectedBalance, ethWithdrawableBalance);

        uint256 starkExpectedBalance = 3e10;
        mockCore.addWithdrawalBalance(starkKey, assetType, starkExpectedBalance);
        uint256 starkWithdrawableBalance = registration.imx().getWithdrawalBalance(starkKey, assetType);
        assertEq(starkExpectedBalance, starkWithdrawableBalance);

        // assure the user is not registered
        assertFalse(registration.isRegistered(starkKey));

        uint256 initialBalance = ethAdd.balance;
        bytes memory regSig = abi.encodePacked(
            uint256(0x06f56e3e7392318ae672ff7d68d1b6c54a6f402019bd121dee9b8d8aa9658ab5), // r
            uint256(0x06c1b98af915c6c1f88ea15f22f2d4f4a7a20c5416cafca0538bf227469dc14a), // s
            uint256(0x02ec99c3c1d90d78dd77676a2505bbeba3cf9ecd1003d72c14949817d84625a4) // starkY
        );
        // act
        registration.registerAndWithdrawAll(ethAdd, starkKey, regSig, assetType);

        // checks final balance
        uint256 finalBalance = ethAdd.balance;
        assertEq(initialBalance + ethExpectedBalance + starkExpectedBalance, finalBalance);

        // checks if the user was registered correctly
        assertEq(ethAdd, registration.imx().getEthKey(starkKey));
    }

    function testRegister_WhenUserIsNotRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // assure the user is not registered
        assertFalse(registration.isRegistered(starkKey));
        assertEq(address(0x0), registration.imx().getEthKey(starkKey));

        bytes memory regSig = abi.encodePacked(
            uint256(0x06f56e3e7392318ae672ff7d68d1b6c54a6f402019bd121dee9b8d8aa9658ab5), // r
            uint256(0x06c1b98af915c6c1f88ea15f22f2d4f4a7a20c5416cafca0538bf227469dc14a), // s
            uint256(0x02ec99c3c1d90d78dd77676a2505bbeba3cf9ecd1003d72c14949817d84625a4) // starkY
        );
        // act
        registration.imx().registerEthAddress(ethAdd, starkKey, regSig);

        // checks if the user was registered correctly
        assertTrue(registration.isRegistered(starkKey));
        assertEq(ethAdd, registration.imx().getEthKey(starkKey));
    }
}
