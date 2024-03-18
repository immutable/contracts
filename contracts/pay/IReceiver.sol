pragma solidity ^0.8.19;

import { Receipt } from "./Processor.sol";

interface IReceiver {

    function onPaymentProcessed(Receipt memory receipt) external;
}
