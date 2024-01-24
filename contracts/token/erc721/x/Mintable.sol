// SPDX-License-Identifier: MIT
// solhint-disable compiler-version, custom-errors, reason-string
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMintable} from "./IMintable.sol";
import {Minting} from "./utils/Minting.sol";

abstract contract Mintable is Ownable, IMintable {
    address public imx;
    mapping(uint256 id => bytes blueprint) public blueprints;

    event AssetMinted(address to, uint256 id, bytes blueprint);

    constructor(address _owner, address _imx) {
        imx = _imx;
        require(_owner != address(0), "Owner must not be empty");
        transferOwnership(_owner);
    }

    modifier onlyOwnerOrIMX() {
        require(msg.sender == imx || msg.sender == owner(), "Function can only be called by owner or IMX");
        _;
    }

    function mintFor(address user, uint256 quantity, bytes calldata mintingBlob) external override onlyOwnerOrIMX {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    function _mintFor(address to, uint256 id, bytes memory blueprint) internal virtual;
}
