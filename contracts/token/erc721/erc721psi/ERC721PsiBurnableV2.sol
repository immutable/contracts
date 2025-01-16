// SPDX-License-Identifier: MIT
/**
 * Inspired by ERC721Psi: https://github.com/estarriolvetch/ERC721Psi
 */
pragma solidity 0.8.19;

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
        (uint256 groupNumber, uint256 groupOffset, bool exists, address owner) = _tokenInfo(_tokenId);
        require(exists, "ERC721Psi: owner query for nonexistent token");

        _beforeTokenTransfers(owner, address(0), _tokenId, 1);

        TokenGroup storage group = tokenOwners[groupNumber];
        (bool changed, uint256 updatedBitMask) = setBitIfNotSet(group.burned, groupOffset);
        if (changed) {
            group.burned = updatedBitMask;
        }

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfers(owner, address(0), _tokenId, 1);
    }

}
