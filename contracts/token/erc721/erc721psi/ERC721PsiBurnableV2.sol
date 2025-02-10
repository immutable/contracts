// SPDX-License-Identifier: MIT
/**
 * Inspired by ERC721Psi: https://github.com/estarriolvetch/ERC721Psi
 */
pragma solidity >=0.8.19 <0.8.29;

import {ERC721PsiV2} from "./ERC721PsiV2.sol";

abstract contract ERC721PsiBurnableV2 is ERC721PsiV2 {
    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 _tokenId) internal virtual {
        // Note: To get here, exists must be true. Hence, it is OK to ignore exists.
        uint256 groupNumber;
        uint256 groupOffset;
        address owner;
        (groupNumber, groupOffset, , owner) = _tokenInfo(_tokenId);

        _beforeTokenTransfers(owner, address(0), _tokenId, 1);

        TokenGroup storage group = tokenOwners[groupNumber];
        group.burned = _setBit(group.burned, groupOffset);

        // Update balances
        balances[owner]--;
        // _burn is called in a loop in burn batch, and hence a more efficient batch
        // burning process would be to have this update to supply happen outside the loop.
        // However, this would mean changing code across the codebase.
        // slither-disable-next-line costly-loop
        supply--;

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfers(owner, address(0), _tokenId, 1);
    }
}
