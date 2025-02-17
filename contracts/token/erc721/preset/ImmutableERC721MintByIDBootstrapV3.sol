// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721MintByIDUpgradeableV3} from "./ImmutableERC721MintByIDUpgradeableV3.sol";
import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC721/ERC721Upgradeable.sol";
import {StorageSlotUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/utils/StorageSlotUpgradeable.sol";


contract ImmutableERC721MintByIDBootstrapV3 is ImmutableERC721MintByIDUpgradeableV3 {
    error NotSupportedDuringBootstrapPhase();

    struct BootstrapTransferRequest {
        address from;
        address to;
        uint256 tokenId;
    }

    /**
     * @dev Set ownership of `tokenId`s to `to`s, irrespective of approvals.
     * @dev To mint, have from address = 0.
     * @dev To burn, have to address = 0.
     * Emits a {Transfer} event.
     */
    function bootstrapPhaseChangeOwnership(BootstrapTransferRequest[] calldata requests) external onlyRole(UPGRADE_ROLE) {
        uint256 supply = _totalSupply;

        for (uint256 i = 0; i < requests.length; i++) {
            BootstrapTransferRequest calldata request = requests[i];
            address from = request.from;
            address to = request.to;
            uint256 tokenId = request.tokenId;

            // Clear approvals from the previous owner
            // TODO Leave this here just in case we add token approval support for bootstrap process
//            delete _tokenApprovals[request.tokenId];

            if (from != address(0)) {
                unchecked {
                    // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
                    // `from`'s balance is the number of token held, which is at least one before the current
                    // transfer.
                    uint256 bal = _getBalance(from);
                    bal -= 1;
                    _setBalance(from, bal);
                    supply -= 1;
                }
            }
            if (to != address(0)) {
                unchecked {
                    // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
                    // all 2**256 token ids to be minted, which in practice is impossible.
                    uint256 bal = _getBalance(to);
                    bal += 1;
                    _setBalance(to, bal);
                    supply += 1;
                }
            }
            _setOwner(tokenId, to);

            emit Transfer(from, to, tokenId);
        }
        _totalSupply = supply;
    }

    // Storage slots determined using 
    // forge inspect ImmutableERC721MintByIDBootstrapV3 storage
    uint256 private constant STORAGE_SLOT_BALANCES = 305;
    uint256 private constant STORAGE_SLOT_OWNERS = 304;

    function _getBalance(address account) private view returns (uint256) {
        bytes32 slot = keccak256(abi.encode(STORAGE_SLOT_BALANCES, account));
        return StorageSlotUpgradeable.getUint256Slot(slot).value;
    }
    function _setBalance(address account, uint256 value) private {
        // TODO does account need to be switched to a uint256?
        bytes32 slot = keccak256(abi.encode(STORAGE_SLOT_BALANCES, account));
        StorageSlotUpgradeable.getUint256Slot(slot).value = value;
    }
    function _setOwner(uint256 tokenId, address owner) private {
        // TODO does account need to be switched to a uint256?
        bytes32 slot = keccak256(abi.encode(STORAGE_SLOT_OWNERS, tokenId));
        StorageSlotUpgradeable.getAddressSlot(slot).value = owner;
    }




    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address /* to */, uint256 /* tokenId */) public virtual override {
        revert NotSupportedDuringBootstrapPhase();
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address /* operator */, bool /* approved */) public virtual override {
        revert NotSupportedDuringBootstrapPhase();
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address /* from */, address /* to */, uint256 /* tokenId */) public virtual override {
        revert NotSupportedDuringBootstrapPhase();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address /* from */, address /* to */, uint256 /* tokenId */) public virtual override {
        revert NotSupportedDuringBootstrapPhase();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address /*from */, address /* to */, uint256 /* tokenId */, bytes memory /* data */) public virtual override(ERC721Upgradeable) {
        revert NotSupportedDuringBootstrapPhase();
    }


// TODO burn functions too need to be removed


    function burnBatch(uint256[] calldata /* tokenIDs */) external pure override {
        revert NotSupportedDuringBootstrapPhase();
    }

    function safeBurnBatch(IDBurn[] calldata /* burns */) external pure override {
        revert NotSupportedDuringBootstrapPhase();
    }

    function safeTransferFromBatch(TransferRequest calldata /* tr */) external virtual override {
        revert NotSupportedDuringBootstrapPhase();
    }




    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __ImmutableERC721MintByIDBootstrapGap;
    // slither-disable-end unused-state
}
