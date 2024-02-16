// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RegistrationV4} from "../../../../contracts/bridge/x/v4/RegistrationV4.sol";
import {Test} from "forge-std/Test.sol";
import {DeployRegistrationV4Dev} from "../../../../script/DeployRegistrationV4Dev.s.sol";
import {MockCoreV4} from "./MockCoreV4.sol";
import {Asset} from "../../../../contracts/token/erc721/x/Asset.sol";
import {console} from "forge-std/console.sol";

contract RegistrationV4Test is Test {
    MockCoreV4 public mockCore;
    RegistrationV4 public registration;

    uint256 private MOCK_CORE_FUNDS = 5e18;

    function setUp() public {
        vm.startBroadcast();
        mockCore = new MockCoreV4();
        registration = new RegistrationV4(payable(mockCore));
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

    function testRegisterAndWithdrawalNFT_WhenUserIsNotRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        // uint256 ethKey = 983301674259619813482344086789227297671214399350;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // arrange
        bytes memory regSig = abi.encodePacked(
            uint256(0x06f56e3e7392318ae672ff7d68d1b6c54a6f402019bd121dee9b8d8aa9658ab5), // r
            uint256(0x06c1b98af915c6c1f88ea15f22f2d4f4a7a20c5416cafca0538bf227469dc14a), // s
            uint256(0x02ec99c3c1d90d78dd77676a2505bbeba3cf9ecd1003d72c14949817d84625a4) // starkY
        );

        // 0x31e2a7a568737baacd430d7750c9bf07dba85ba60d13b6b6fe8d47e8d13aa21
        uint256 assetType = 1410237129265691706741215969248966526395742991743406915223458527859231140385;
        uint256 quantity = 1;
        uint256 tokenId = 6;

        // arrange nft contract
        Asset nftContract = new Asset(address(this), "name", "symbol", address(registration.imx()));
        mockCore.addTokenContract(assetType, address(nftContract));
        mockCore.addWithdrawalBalance(starkKey, assetType + tokenId, 1);
        nftContract.mintFor(address(mockCore), quantity, abi.encodePacked("{6}:{onchain-metadata}"));

        // pre-checks
        assertFalse(registration.isRegistered(starkKey));
        assertEq(0, nftContract.balanceOf(ethAdd));

        // act
        registration.registerAndWithdrawNft(ethAdd, starkKey, regSig, assetType, tokenId);

        // assert
        assertTrue(registration.isRegistered(starkKey));
        assertEq(quantity, nftContract.balanceOf(ethAdd));
    }

    function testRegisterWithdrawalAndMintNFT_WhenUserIsNotRegistered() public {
        address ethAdd = 0xac3cc5a41D9e8c94Fe64138C1343A07B2fF5ff76;
        // uint256 ethKey = 983301674259619813482344086789227297671214399350;
        // 0x7a88d4e1a357d33d6168058ac6b08fa54c07b72313f78af594d4d44e8268a6c
        uint256 starkKey = 3463995498836494504631329032145085468217956335318243415256427132985150966380;

        // arrange
        bytes memory regSig = abi.encodePacked(
            uint256(0x06f56e3e7392318ae672ff7d68d1b6c54a6f402019bd121dee9b8d8aa9658ab5), // r
            uint256(0x06c1b98af915c6c1f88ea15f22f2d4f4a7a20c5416cafca0538bf227469dc14a), // s
            uint256(0x02ec99c3c1d90d78dd77676a2505bbeba3cf9ecd1003d72c14949817d84625a4) // starkY
        );

        // 0x31e2a7a568737baacd430d7750c9bf07dba85ba60d13b6b6fe8d47e8d13aa21
        uint256 assetType = 1410237129265691706741215969248966526395742991743406915223458527859231140385;
        uint256 quantity = 1;
        uint256 tokenId = 7;

        // arrange nft contract
        Asset nftContract = new Asset(address(this), "name", "symbol", address(registration.imx()));
        mockCore.addTokenContract(assetType, address(nftContract));
        mockCore.addWithdrawalBalance(starkKey, assetType + tokenId, 1);

        // pre-checks
        assertFalse(registration.isRegistered(starkKey));
        assertEq(0, nftContract.balanceOf(ethAdd));

        // act
        registration.registerWithdrawAndMint(
            ethAdd, starkKey, regSig, assetType, abi.encodePacked("{7}:{onchain-metadata}")
        );

        // assert
        assertTrue(registration.isRegistered(starkKey));
        assertEq(quantity, nftContract.balanceOf(ethAdd));
    }
}
