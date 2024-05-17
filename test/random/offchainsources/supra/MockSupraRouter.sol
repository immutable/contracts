// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ISupraRouter} from "../../../../contracts/random/offchainsources/supra/ISupraRouter.sol";
import {SupraSourceAdaptor} from "../../../../contracts/random/offchainsources/supra/SupraSourceAdaptor.sol";

contract MockSupraRouter is ISupraRouter {
    event RequestId(uint256 _requestId);

    SupraSourceAdaptor public adaptor;
    uint256 public nextIndex = 1000;

    uint64 private subscriptionId = uint64(0);
    bool private pending = false;

    function setAdaptor(address _adaptor) external {
        adaptor = SupraSourceAdaptor(_adaptor);
    }

    function sendFulfill(uint256 _requestId, uint256 _rand) external {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = _rand;
        adaptor.fulfillRandomWords(_requestId, randomWords);
    }

    function sendFulfillRaw(uint256 _requestId, uint256[] calldata _rand) external {
        adaptor.fulfillRandomWords(_requestId, _rand);
    }

    function generateRequest(
        string memory, /* _functionSig */
        uint8, /* _rngCount */
        uint256, /* _numConfirmations */
        address /* _clientWalletAddress */
    ) external returns (uint256 requestId) {
        requestId = nextIndex++;
        emit RequestId(requestId);
    }

    // Unused functions
    function generateRequest(
        string memory, /* _functionSig */
        uint8, /* _rngCount */
        uint256, /* _numConfirmations */
        uint256, /* _clientSeed */
        address /* _clientWalletAddress */
    ) external returns (uint256 requestId) {
        requestId = nextIndex++;
        emit RequestId(requestId);
    }
}
