// SPDX-License-Identifier: MIT
// solhint-disable compiler-version
pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Mintable} from "./Mintable.sol";

// slither-disable-start missing-inheritance
contract Asset is ERC721, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    function _mintFor(address user, uint256 id, bytes memory) internal override {
        _safeMint(user, id);
    }
}
// slither-disable-end missing-inheritance
