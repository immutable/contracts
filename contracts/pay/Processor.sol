pragma solidity ^0.8.19;

import { IReceiver } from "./IReceiver.sol";
import { IRouter } from "./IRouter.sol";
import { IWrapper } from "./IWrapper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Order {
    address purchasedFor; // the user who should receive the purchase
    uint256 paymentAmount; // the amount the user is paying (in paymentToken)
    address paymentToken; // the token the user is paying in
    uint256 pricingAmount;
    address pricingToken; // the token the sale is priced in
    address receiver; // address of the sale contract
    address recipient;
    bytes extraData;
    bool allowSwap;
}

struct Receipt {
    uint256 id;
    Order order;
    address paidToken;
    uint256 paidAmount;
}

contract Processor { 

    uint256 public counter;
    IRouter public router;
    IWrapper public wrappedNativeToken; 
    uint8 public feePercentage;
    address public feeRecipient;

    event PaymentProcessed(uint256 indexed id, Order order);
    error IncorrectValue(uint256 msgValue, uint256 paymentAmount);
    error InsufficientPaymentAmount(uint256 required, uint256 received);
    error FailedNativeTokenTransfer();

    constructor(
        IRouter _router,
        IWrapper _wrappedNativeToken,
        uint8 _feePercentage,
        address _feeRecipient
    ) {
        router = _router;
        wrappedNativeToken = _wrappedNativeToken;
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
    }

    function process(Order calldata order) external {

        Receipt memory receipt;
        uint256 id = counter++;

        if (order.paymentToken == address(0)) {
            receipt = _handleNativeTokenPayment(id, order);
        } else {
            receipt = _handleERC20Payment(id, order);
        }

        // Receiver can be left blank if no on-chain actions are required
        if (order.receiver != address(0)) {
            IReceiver(order.receiver).onPaymentProcessed(receipt);
        }
    }

    function _handleNativeTokenPayment(uint256 id, Order memory order) internal returns (Receipt memory) {
        if (msg.value != order.paymentAmount) {
            revert IncorrectValue(msg.value, order.paymentAmount);
        }
        if (order.pricingToken == order.paymentToken) {
            // priced in native currency

            _payFeeAndTransferNativeToken(msg.value, order.recipient);

            return Receipt({
                id: id,
                order: order,
                paidToken: order.pricingToken,
                paidAmount: msg.value
            });
        } else {
            if (order.allowSwap) {
                // wrap token, then swap
                wrappedNativeToken.deposit{value: msg.value}();
                uint256 paymentAmount = _executeSwap(
                    address(wrappedNativeToken),
                    order.paymentAmount,
                    order.pricingToken,
                    order.pricingAmount
                );

                _payFeeAndTransferERC20(order.pricingToken, order.pricingAmount, order.recipient);

                return Receipt({
                    id: id,
                    order: order,
                    paidToken: order.pricingToken,
                    paidAmount: order.pricingAmount
                });

            } else {
                // the user is relying on the sale contract to accept their payment currency
                uint256 quote = getQuote(
                    address(wrappedNativeToken),
                    order.pricingToken,
                    order.pricingAmount
                );

                if (quote > order.paymentAmount) {
                    revert InsufficientPaymentAmount(quote, order.paymentAmount);
                }

                if (quote < msg.value) {
                    // return excess funds to the user
                    _send(msg.sender, msg.value - quote);
                }

                _payFeeAndTransferNativeToken(quote, order.recipient);

                // the user is relying on the sale contract to accept their payment currency
                return Receipt({
                    id: id,
                    order: order,
                    paidToken: order.paymentToken,
                    paidAmount: quote
                });
                
            }
        }
    }

    function _handleERC20Payment(uint256 id, Order memory order) internal returns (Receipt memory) {

        if (order.pricingToken == order.paymentToken) {

            // TODO: fees
            IERC20(order.paymentToken).transferFrom(msg.sender, order.recipient, order.paymentAmount);
            return Receipt({
                id: id,
                order: order,
                paidToken: order.pricingToken,
                paidAmount: order.paymentAmount
            });
        } else {
            if (order.allowSwap) {

                uint256 paymentAmount = _executeSwap(
                    order.paymentToken,
                    order.paymentAmount,
                    order.pricingToken,
                    order.pricingAmount
                );

                _payFeeAndTransferERC20(order.pricingToken, order.pricingAmount, order.recipient);

                return Receipt({
                    id: id,
                    order: order,
                    paidToken: order.pricingToken,
                    paidAmount: order.pricingAmount
                });
                
            } else {

                uint256 quote = getQuote(
                    order.paymentToken,
                    order.pricingToken,
                    order.pricingAmount
                );

                if (quote > order.paymentAmount) {
                    revert InsufficientPaymentAmount(quote, order.paymentAmount);
                }

                _payFeeAndTransferERC20(order.paymentToken, quote, order.recipient);

                // the user is relying on the sale contract to accept their payment currency
                return Receipt({
                    id: id,
                    order: order,
                    paidToken: order.paymentToken,
                    paidAmount: quote
                });
            }
        }
    }

    function _executeSwap(address from, uint256 amountInMax, address to, uint256 exactAmountOut) internal returns (uint256 amountSwapped) {
        
        IERC20(from).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(from).approve(address(router), amountInMax);

        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        
        uint256[] memory amounts = router.swapTokensForExactTokens(
            exactAmountOut, amountInMax, path, address(this), block.timestamp
        );

        // Refund WETH to msg.sender
        if (amounts[0] < amountInMax) {
            IERC20(from).transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[0];
    }

    function getQuote(address from, address to, uint256 exactAmountOut) public returns (uint256 quote) {

        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        
        uint256[] memory amounts = router.getAmountsOut(exactAmountOut, path);

        return amounts[0];
    }

    function _send(address to, uint256 value) internal {
        (bool sent,) = to.call{value: value}("");
        if (!sent) {
            revert FailedNativeTokenTransfer();
        }
    }

    function _payFeeAndTransferERC20(address token, uint256 amount, address recipient) internal {
        uint256 fee = _calculateFee(amount);
        IERC20(token).transfer(feeRecipient, fee);
        IERC20(token).transfer(recipient, amount - fee);
    }

    function _payFeeAndTransferNativeToken(uint256 amount, address recipient) internal {
        uint256 fee = _calculateFee(amount);
        _send(feeRecipient, fee);
        _send(recipient, amount - fee);
    }

    function _calculateFee(uint256 value) internal view returns (uint256 fee) {
        return (value / 100) * feePercentage;
    }


}