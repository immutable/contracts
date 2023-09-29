// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IRootERC20BridgeAdaptor} from "./interfaces/IRootERC20BridgeAdaptor.sol";
import {IAxelarBridgeAdaptorEvents, IAxelarBridgeAdaptorErrors} from "./interfaces/IAxelarBridgeAdaptor.sol";

// TODO Note: this will have to be an AxelarExecutable contract in order to receive messages

/**
 * @notice RootAxelarBridgeAdaptor is a bridge adaptor that allows the RootERC20Bridge to communicate with the Axelar Gateway.
 * @dev This is not an upgradeable contract, because it is trivial to deploy a new one if needed.
 */
contract RootAxelarBridgeAdaptor is IRootERC20BridgeAdaptor, IAxelarBridgeAdaptorEvents, IAxelarBridgeAdaptorErrors {
    using SafeERC20 for IERC20Metadata;

    address public immutable ROOT_BRIDGE;
    /// @dev childBridgeAdaptor & childChain could be immutable, but as of writing this Solidity does not support immutable strings.
    ///      see: https://ethereum.stackexchange.com/questions/127622/typeerror-immutable-variables-cannot-have-a-non-value-type
    string public childBridgeAdaptor;
    string public childChain;
    IAxelarGateway public immutable AXELAR_GATEWAY;
    IAxelarGasService public immutable GAS_SERVICE;
    mapping(uint256 => string) public chainIdToChainName;

    constructor(
        address _rootBridge,
        address _childBridgeAdaptor,
        string memory _childChain,
        address _axelarGateway,
        address _gasService
    ) {
        if (
            _rootBridge == address(0) ||
            _childBridgeAdaptor == address(0) ||
            _axelarGateway == address(0) ||
            _gasService == address(0)
        ) {
            revert ZeroAddresses();
        }

        if (bytes(_childChain).length == 0) {
            revert InvalidChildChain();
        }
        ROOT_BRIDGE = _rootBridge;
        childBridgeAdaptor = Strings.toHexString(_childBridgeAdaptor);
        childChain = _childChain;
        AXELAR_GATEWAY = IAxelarGateway(_axelarGateway);
        GAS_SERVICE = IAxelarGasService(_gasService);
    }

    /**
     * @inheritdoc IRootERC20BridgeAdaptor
     * @notice Sends an arbitrary message to the child chain, via the Axelar network.
     */
    function sendMessage(bytes calldata payload, address refundRecipient) external payable override {
        if (msg.value == 0) {
            revert NoGas();
        }
        if (msg.sender != ROOT_BRIDGE) {
            revert CallerNotBridge();
        }

        // Load from storage.
        string memory _childBridgeAdaptor = childBridgeAdaptor;
        string memory _childChain = childChain;

        // TODO For other functions (depositing to chain), the refund recipient should be the user doing the deposit
        GAS_SERVICE.payNativeGasForContractCall{value: msg.value}(
            address(this),
            _childChain,
            _childBridgeAdaptor,
            payload,
            refundRecipient
        );

        AXELAR_GATEWAY.callContract(_childChain, _childBridgeAdaptor, payload);
        emit MapTokenAxelarMessage(_childChain, _childBridgeAdaptor, payload);
    }

    // TODO future tickets
    function receiveWithdrawMessage(bytes calldata payload) external {
        // TODO
    }

    function sendDepositMessage(address l1Token, address recipient, uint256 amount) external {
        // TODO
    }
}
