// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721MintByIDUpgradeableV3} from "./ImmutableERC721MintByIDUpgradeableV3.sol";
import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC721/ERC721Upgradeable.sol";


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

            // Clear approvals from the previous owner
            // Leave this here just in case we add token approval support for bootstrap process
//            delete _tokenApprovals[request.tokenId];

            if (request.from != address(0)) {
                unchecked {
                    // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
                    // `from`'s balance is the number of token held, which is at least one before the current
                    // transfer.
//                    _balances[request.from] -= 1;
                    supply -= 1;
                }
            }
            if (request.to != address(0)) {
                unchecked {
                    // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
                    // all 2**256 token ids to be minted, which in practice is impossible.
//                    _balances[request.to] += 1;
                    supply += 1;
                }
            }
//            _owners[request.tokenId] = request.to;

            emit Transfer(request.from, request.to, request.tokenId);
        }
        _totalSupply = supply;
    }

    function getBalance(address account) private view returns (uint256) {

    }
    function setBalance(address account, uint256 value) private {
        
    }
    function setOwner(uint256 tokenId, address owner) private {
        
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
