// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IAxelarGateway} from "@axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IRootERC20Bridge, IERC20Metadata} from "./interfaces/IRootERC20Bridge.sol";
import {IRootERC20BridgeEvents, IRootERC20BridgeErrors} from "./interfaces/IRootERC20Bridge.sol";
import {IRootERC20BridgeAdaptor} from "./interfaces/IRootERC20BridgeAdaptor.sol";

/**
 * @notice RootERC20Bridge is a bridge that allows ERC20 tokens to be transferred from the root chain to the child chain.
 * @dev This contract is designed to be upgradeable.
 * @dev Follows a pattern of using a bridge adaptor to communicate with the child chain. This is because the underlying communication protocol may change,
 *      and also allows us to decouple vendor-specific messaging logic from the bridge logic.
 * @dev Because of this pattern, any checks or logic that is agnostic to the messaging protocol should be done in RootERC20Bridge.
 * @dev Any checks or logic that is specific to the underlying messaging protocol should be done in the bridge adaptor.
 */
contract RootERC20Bridge is
    Ownable2Step,
    Initializable,
    IRootERC20Bridge,
    IRootERC20BridgeEvents,
    IRootERC20BridgeErrors
{
    using SafeERC20 for IERC20Metadata;

    IRootERC20BridgeAdaptor public bridgeAdaptor;
    /// @dev The address that will be minting tokens on the child chain.
    address public childERC20Bridge;
    /// @dev The address of the token template that will be cloned to create tokens on the child chain.
    address public childTokenTemplate;
    mapping(address => address) public rootTokenToChildToken;

    /**
     * @notice Initilization function for RootERC20Bridge.
     * @param newBridgeAdaptor Address of StateSender to send deposit information to.
     * @param newChildERC20Bridge Address of child ERC20 bridge to communicate with.
     * @param newChildTokenTemplate Address of child token template to clone.
     * @dev Can only be called once.
     */
    function initialize(
        address newBridgeAdaptor,
        address newChildERC20Bridge,
        address newChildTokenTemplate
    ) public initializer {
        if (
            newBridgeAdaptor == address(0) || newChildERC20Bridge == address(0) || newChildTokenTemplate == address(0)
        ) {
            revert ZeroAddress();
        }
        childERC20Bridge = newChildERC20Bridge;
        childTokenTemplate = newChildTokenTemplate;
        bridgeAdaptor = IRootERC20BridgeAdaptor(newBridgeAdaptor);
    }

    /**
     * @inheritdoc IRootERC20Bridge
     */
    function mapToken(IERC20Metadata rootToken) external payable override returns (address) {
        if (address(rootToken) == address(0)) {
            revert ZeroAddress();
        }
        if (rootTokenToChildToken[address(rootToken)] != address(0)) {
            revert AlreadyMapped();
        }

        address childBridge = childERC20Bridge;

        address childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childBridge
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        bridgeAdaptor.mapToken{value: msg.value}(
            address(rootToken),
            rootToken.name(),
            rootToken.symbol(),
            rootToken.decimals()
        );

        emit TokenMapped(address(rootToken), childToken);
        return childToken;
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
        bridgeAdaptor = IRootERC20BridgeAdaptor(newBridgeAdaptor);
    }
}
