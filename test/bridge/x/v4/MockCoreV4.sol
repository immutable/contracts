// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CoreV4} from "../../../../contracts/bridge/x/v4/CoreV4.sol";
import {Asset} from "../../../../contracts/token/erc721/x/Asset.sol";
import {Minting} from "../../../../contracts/token/erc721/x/utils/Minting.sol";

contract MockCoreV4 is CoreV4 {
    address internal ZERO_ADDRESS = address(0);

    // Mapping from STARK public key to the Ethereum public key of its owner.
    mapping(uint256 => address) internal ethKeys; // NOLINT: uninitialized-state.

    // Pending withdrawals.
    // A map STARK key => asset id => quantized amount.
    mapping(uint256 => mapping(uint256 => uint256)) internal pendingWithdrawals;

    uint256 internal constant MASK_ADDRESS = (1 << 160) - 1;

    // Pending withdrawals.
    // A map asset type => contract address.
    mapping(uint256 => address) internal tokenContracts;

    fallback() external payable {
        revert();
    }

    function VERSION() external pure override returns (string memory) {
        return "4.0.1";
    }

    function initialize(bytes memory) external pure override {
        revert("Not implemented");
    }

    receive() external payable {
        revert();
    }

    function DEPOSIT_CANCEL_DELAY() external pure override returns (uint256) {
        return 0;
    }

    function FREEZE_GRACE_PERIOD() external pure override returns (uint256) {
        return 0;
    }

    function MAIN_GOVERNANCE_INFO_TAG() external pure override returns (string memory) {
        return "governance_info";
    }

    function MAX_FORCED_ACTIONS_REQS_PER_BLOCK() external pure override returns (uint256) {
        return 0;
    }

    function MAX_VERIFIER_COUNT() external pure override returns (uint256) {
        return 0;
    }

    function UNFREEZE_DELAY() external pure override returns (uint256) {
        return 0;
    }

    function VERIFIER_REMOVAL_DELAY() external pure override returns (uint256) {
        return 0;
    }

    function announceAvailabilityVerifierRemovalIntent(address) external pure override {
        revert("Not implemented");
    }

    function announceVerifierRemovalIntent(address) external pure override {
        revert("Not implemented");
    }

    function getRegisteredAvailabilityVerifiers() external pure override returns (address[] memory _verifers) {
        // Placeholder implementation, returning an empty array
        address[] memory verifiers;
        return verifiers;
    }

    function getRegisteredVerifiers() external pure override returns (address[] memory _verifers) {
        // Placeholder implementation, returning an empty array
        address[] memory verifiers;
        return verifiers;
    }

    function isAvailabilityVerifier(address) external pure override returns (bool) {
        return false;
    }

    function isFrozen() external pure override returns (bool) {
        return false;
    }

    function isVerifier(address) external pure override returns (bool) {
        return false;
    }

    function mainAcceptGovernance() external pure override {
        revert("Not implemented");
    }

    function mainCancelNomination() external pure override {
        revert("Not implemented");
    }

    function mainIsGovernor(address) external pure override returns (bool) {
        return false;
    }

    function mainNominateNewGovernor(address) external pure override {
        revert("Not implemented");
    }

    function mainRemoveGovernor(address) external pure override {
        revert("Not implemented");
    }

    function registerAvailabilityVerifier(address, string memory) external pure override {
        revert("Not implemented");
    }

    function registerVerifier(address, string memory) external pure override {
        revert("Not implemented");
    }

    function removeAvailabilityVerifier(address) external pure override {
        revert("Not implemented");
    }

    function removeVerifier(address) external pure override {
        revert("Not implemented");
    }

    function unFreeze() external pure override {
        revert("Not implemented");
    }

    function defaultVaultWithdrawalLock() external pure override returns (uint256) {
        return 0;
    }

    function deposit(uint256, uint256, uint256) external payable override {
        revert("Not implemented");
    }

    function deposit(uint256, uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function depositCancel(uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function depositERC20(uint256, uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function depositEth(uint256, uint256, uint256) external payable override {
        revert("Not implemented");
    }

    function depositNft(uint256, uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function depositNftReclaim(uint256, uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function depositReclaim(uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function getActionCount() external pure override returns (uint256) {
        return 0;
    }

    function getActionHashByIndex(uint256) external pure override returns (bytes32) {
        revert("Not implemented");
    }

    function getAssetInfo(uint256) external pure override returns (bytes memory) {
        revert("Not implemented");
    }

    function getCancellationRequest(uint256, uint256, uint256) external pure override returns (uint256) {
        revert("Not implemented");
    }

    function getDepositBalance(uint256, uint256, uint256) external pure override returns (uint256) {
        revert("Not implemented");
    }

    function getEthKey(uint256 ownerKey) public view override returns (address) {
        address registeredEth = ethKeys[ownerKey];

        if (registeredEth != address(0x0)) {
            return registeredEth;
        }

        return ownerKey == (ownerKey & MASK_ADDRESS) ? address(uint160(ownerKey)) : address(0x0);
    }

    function getFullWithdrawalRequest(uint256, uint256) external pure override returns (uint256) {
        revert("Not implemented");
    }

    function getQuantizedDepositBalance(uint256, uint256, uint256) external pure override returns (uint256) {
        revert("Not implemented");
    }

    function getQuantum(uint256) external pure override returns (uint256) {
        revert("Not implemented");
    }

    function addWithdrawalBalance(uint256 ownerKey, uint256 assetId, uint256 balance) external {
        pendingWithdrawals[ownerKey][assetId] += balance;
    }

    function getWithdrawalBalance(uint256 ownerKey, uint256 assetId) external view override returns (uint256) {
        return pendingWithdrawals[ownerKey][assetId];
    }

    function isAssetRegistered(uint256) external pure override returns (bool) {
        revert("Not implemented");
    }

    function isTokenAdmin(address) external pure override returns (bool) {
        revert("Not implemented");
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function orderRegistryAddress() external pure override returns (address) {
        revert("Not implemented");
    }

    function registerAndDepositERC20(address, uint256, bytes memory, uint256, uint256, uint256)
        external
        pure
        override
    {
        revert("Not implemented");
    }

    function registerAndDepositEth(address, uint256, bytes memory, uint256, uint256) external payable override {
        revert("Not implemented");
    }

    function registerEthAddress(address ethKey, uint256 starkKey, bytes memory starkSignature) external override {
        // Validate keys and availability.
        require(starkKey != 0, "INVALID_STARK_KEY");
        require(ethKey != ZERO_ADDRESS, "INVALID_ETH_ADDRESS");
        require(ethKeys[starkKey] == ZERO_ADDRESS, "STARK_KEY_UNAVAILABLE");
        require(starkSignature.length == 32 * 3, "INVALID_STARK_SIGNATURE_LENGTH");

        // Update state.
        ethKeys[starkKey] = ethKey;

        // Log new user.
        emit LogUserRegistered(ethKey, starkKey, msg.sender);
    }

    function registerSender(uint256, bytes memory) external pure override {
        revert("Not implemented");
    }

    function registerToken(uint256, bytes memory) external pure override {
        revert("Not implemented");
    }

    function addTokenContract(uint256 assetType, address tokenContract) external {
        tokenContracts[assetType] = tokenContract;
    }

    function registerToken(uint256, bytes memory, uint256) external pure override {
        revert("Not implemented");
    }

    function registerTokenAdmin(address) external pure override {
        revert("Not implemented");
    }

    function unregisterTokenAdmin(address) external pure override {
        revert("Not implemented");
    }

    function withdraw(uint256 ownerKey, uint256 assetType) external override {
        address payable recipient = payable(getEthKey(ownerKey));
        require(recipient != ZERO_ADDRESS, "USER_UNREGISTERED");
        uint256 assetId = assetType;
        // Fetch and clear quantized amount.
        uint256 amount = pendingWithdrawals[ownerKey][assetId];
        pendingWithdrawals[ownerKey][assetId] = 0;

        // Transfer funds.
        (bool success,) = recipient.call{value: amount}(""); // NOLINT: low-level-calls.
        require(success, "TRANSFER_ERROR");
        emit LogWithdrawalPerformed(ownerKey, assetType, amount, amount, recipient);
    }

    function withdrawAndMint(uint256 ownerKey, uint256 assetType, bytes calldata mintingBlob) external override {
        address payable recipient = payable(getEthKey(ownerKey));
        require(recipient != ZERO_ADDRESS, "USER_UNREGISTERED");

        (uint256 tokenId,) = Minting.split(mintingBlob);
        uint256 assetId = assetType + tokenId;
        uint256 amount = pendingWithdrawals[ownerKey][assetId];
        pendingWithdrawals[ownerKey][assetId] = 0;
        require(amount == 1, "INVALID_AMOUNT");

        // Make sure we don't accidentally burn funds.
        require(recipient != address(0x0), "INVALID_RECIPIENT");
        address tokenAddress = tokenContracts[assetType];
        require(tokenAddress != address(0x0), "INVALID_CONTRACT");

        Asset(tokenAddress).mintFor(address(recipient), amount, mintingBlob);
    }

    function withdrawNft(uint256 ownerKey, uint256 assetType, uint256 tokenId) external override {
        uint256 assetId = assetType + tokenId;

        address payable recipient = payable(getEthKey(ownerKey));
        require(recipient != ZERO_ADDRESS, "USER_UNREGISTERED");

        uint256 amount = pendingWithdrawals[ownerKey][assetId];
        pendingWithdrawals[ownerKey][assetId] = 0;

        require(amount == 1, "INVALID_AMOUNT");

        // Transfer funds.
        transferOutNft(recipient, assetType, tokenId);

        emit LogNftWithdrawalPerformed(ownerKey, assetType, tokenId, assetId, recipient);
    }

    function transferOutNft(address recipient, uint256 assetType, uint256 tokenId) internal {
        // Make sure we don't accidentally burn funds.
        require(recipient != address(0x0), "INVALID_RECIPIENT");
        address tokenAddress = tokenContracts[assetType];
        require(tokenAddress != address(0x0), "INVALID_CONTRACT");

        Asset(tokenAddress).safeTransferFrom(address(this), recipient, tokenId);
    }

    function STARKEX_MAX_DEFAULT_VAULT_LOCK() external pure override returns (uint256) {
        return 0;
    }

    function escape(uint256, uint256, uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function getLastBatchId() external pure override returns (uint256) {
        return 0;
    }

    function getOrderRoot() external pure override returns (uint256) {
        return 0;
    }

    function getOrderTreeHeight() external pure override returns (uint256) {
        return 0;
    }

    function getSequenceNumber() external pure override returns (uint256) {
        return 0;
    }

    function getVaultRoot() external pure override returns (uint256) {
        return 0;
    }

    function getVaultTreeHeight() external pure override returns (uint256) {
        return 0;
    }

    function isOperator(address) external pure override returns (bool) {
        return false;
    }

    function registerOperator(address) external pure override {
        revert("Not implemented");
    }

    function unregisterOperator(address) external pure override {
        revert("Not implemented");
    }

    function updateState(uint256[] memory, uint256[] memory) external pure override {
        revert("Not implemented");
    }

    function freezeRequest(uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function fullWithdrawalRequest(uint256, uint256) external pure override {
        revert("Not implemented");
    }

    function depositERC20ToVault(uint256, uint256, uint256) external pure {
        revert("Not implemented");
    }

    function depositEthToVault(uint256, uint256) external payable {
        revert("Not implemented");
    }

    function getQuantizedVaultBalance(address, uint256, uint256) external pure returns (uint256) {
        revert("Not implemented");
    }

    function getVaultBalance(address, uint256, uint256) external pure returns (uint256) {
        revert("Not implemented");
    }

    function getVaultWithdrawalLock(address, uint256, uint256) external pure returns (uint256) {
        revert("Not implemented");
    }

    function isStrictVaultBalancePolicy() external pure returns (bool) {
        revert("Not implemented");
    }

    function isVaultLocked(address, uint256, uint256) external pure returns (bool) {
        revert("Not implemented");
    }

    function lockVault(uint256, uint256, uint256) external pure {
        revert("Not implemented");
    }

    function setDefaultVaultWithdrawalLock(uint256) external pure {
        revert("Not implemented");
    }

    function updateImplementationActivationTime(address, bytes memory, bool) external pure {
        revert("Not implemented");
    }

    function withdrawFromVault(uint256, uint256, uint256) external pure {
        revert("Not implemented");
    }
}
