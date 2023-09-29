// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // TODO hardhat config compiles with 0.8.17. We should investigate upgrading this.

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import {IChildERC20BridgeEvents, IChildERC20BridgeErrors, IChildERC20Bridge, IERC20Metadata} from "./interfaces/IChildERC20Bridge.sol";
import {IChildERC20BridgeAdaptor} from "./interfaces/IChildERC20BridgeAdaptor.sol";
import {IChildERC20} from "./interfaces/IChildERC20.sol";

/**
 * @notice RootERC20Bridge is a bridge that allows ERC20 tokens to be transferred from the root chain to the child chain.
 * @dev This contract is designed to be upgradeable.
 * @dev Follows a pattern of using a bridge adaptor to communicate with the child chain. This is because the underlying communication protocol may change,
 *      and also allows us to decouple vendor-specific messaging logic from the bridge logic.
 * @dev Because of this pattern, any checks or logic that is agnostic to the messaging protocol should be done in RootERC20Bridge.
 * @dev Any checks or logic that is specific to the underlying messaging protocol should be done in the bridge adaptor.
 */
contract ChildERC20Bridge is
    Ownable2Step,
    Initializable,
    IChildERC20BridgeErrors,
    IChildERC20Bridge,
    IChildERC20BridgeEvents
{
    using SafeERC20 for IERC20Metadata;

    IChildERC20BridgeAdaptor public bridgeAdaptor;
    /// @dev The address that will be sending messages to, and receiving messages from, the child chain.
    address public rootERC20BridgeAdaptor;
    /// @dev The address of the token template that will be cloned to create tokens.
    address public childTokenTemplate;
    /// @dev The name of the chain that this bridge is connected to.
    string public sourceChain;
    mapping(address => address) public rootTokenToChildToken;

    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    /**
     * @notice Initilization function for RootERC20Bridge.
     * @param newBridgeAdaptor Address of StateSender to send deposit information to.
     * @param newRootERC20BridgeAdaptor Address of root ERC20 bridge adaptor to communicate with.
     * @param newChildTokenTemplate Address of child token template to clone.
     * @dev Can only be called once.
     */
    function initialize(
        address newBridgeAdaptor,
        address newRootERC20BridgeAdaptor,
        address newChildTokenTemplate,
        string storage newSourceChain
    ) public initializer {
        if (
            newBridgeAdaptor == address(0) || newRootERC20BridgeAdaptor == address(0) || newChildTokenTemplate == address(0)
        ) {
            revert ZeroAddress();
        }
        rootERC20BridgeAdaptor = newRootERC20BridgeAdaptor;
        childTokenTemplate = newChildTokenTemplate;
        bridgeAdaptor = IChildERC20BridgeAdaptor(newBridgeAdaptor);
        sourceChain = newSourceChain;
    }

    /**
     * @inheritdoc IChildERC20Bridge
     */
    function onMessageReceive(string calldata sourceChain, address sourceAddress, bytes calldata data) external override {
        if (msg.sender != bridgeAdaptor) {
            revert NotBridgeAdaptor();
        }
        if (!Strings.equal(sourceChain, sourceChain)) {
            revert InvalidSourceChain();
        }
        if (sourceAddress != rootERC20BridgeAdaptor) {
            revert InvalidSourceAddress();
        }
        if (data.length == 0) {
            revert InvalidData();
        }

        if (bytes32(data[:32]) == MAP_TOKEN_SIG) {
            _mapToken(data);
        } else {
            revert InvalidData();
        }
    }

    function _mapToken(bytes calldata data) private override {
        (bytes32 _, address rootToken, string memory name, string memory symbol, uint8 decimals) = abi.decode(data, (bytes32, address, string, string, uint8));

        if (address(rootToken) == address(0)) {
            revert ZeroAddress();
        }
        if (rootTokenToChildToken[address(rootToken)] != address(0)) {
            revert AlreadyMapped();
        }

        IChildERC20 childToken = IChildERC20(
            Clones.cloneDeterministic(childTokenTemplate, keccak256(abi.encodePacked(rootToken)))
        );

        rootTokenToChildToken[rootToken] = address(childToken);
        childToken.initialize(rootToken, name, symbol, decimals);

        emit L2TokenMapped(address(rootToken), address(childToken));
    }

    /// @dev To receive ETH refunds from the bridge.
    receive() external payable {}

    /**
     * @notice To withdraw any ETH from this contract which may have been given by the bridge network as refunds.
     */
    function withdrawEth(address payable recipient, uint256 amount) external onlyOwner {
        Address.sendValue(recipient, amount);
    }

    function updateBridgeAdaptor(address newBridgeAdaptor) external onlyOwner {
        if (newBridgeAdaptor == address(0)) {
            revert ZeroAddress();
        }
        bridgeAdaptor = IChildERC20BridgeAdaptor(newBridgeAdaptor);
    }
}
