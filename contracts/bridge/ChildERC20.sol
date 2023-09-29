// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./lib/EIP712MetaTransaction.sol";
import "./interfaces/IChildERC20.sol";

/**
 *   @title ChildERC20
 *   @author Polygon Technology (@QEDK)
 *   @notice Child token template for ChildERC20 predicate deployments
 *   @dev All child tokens are clones of this contract. Burning and minting is controlled by respective predicates only.
 */
// solhint-disable reason-string
contract ChildERC20 is EIP712MetaTransaction, ERC20Upgradeable, IChildERC20 {
    address private _bridge;
    address private _rootToken;
    uint8 private _decimals;

    modifier onlyBridge() {
        require(msg.sender == _bridge, "ChildERC20: Only bridge can call");
        _;
    }

    /**
     * @inheritdoc IChildERC20
     */
    function initialize(
        address rootToken_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_
    ) external initializer {
        require(
            rootToken_ != address(0) && bytes(name_).length != 0 && bytes(symbol_).length != 0,
            "ChildERC20: BAD_INITIALIZATION"
        );
        _rootToken = rootToken_;
        _decimals = decimals_;
        _bridge = msg.sender;
        __ERC20_init(name_, symbol_);
        _initializeEIP712(name_, "1");
    }

    /**
     * @notice Returns the decimals places of the token
     * @return uint8 Returns the decimals places of the token.
     */
    function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return _decimals;
    }

    /**
     * @inheritdoc IChildERC20
     */
    function bridge() external view virtual returns (address) {
        return _bridge;
    }

    /**
     * @inheritdoc IChildERC20
     */
    function rootToken() external view virtual returns (address) {
        return _rootToken;
    }

    /**
     * @inheritdoc IChildERC20
     */
    function mint(address account, uint256 amount) external virtual onlyBridge returns (bool) {
        _mint(account, amount);

        return true;
    }

    /**
     * @inheritdoc IChildERC20
     */
    function burn(address account, uint256 amount) external virtual onlyBridge returns (bool) {
        _burn(account, amount);

        return true;
    }

    function _msgSender() internal view virtual override(EIP712MetaTransaction, ContextUpgradeable) returns (address) {
        return EIP712MetaTransaction._msgSender();
    }
}