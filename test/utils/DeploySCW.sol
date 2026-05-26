// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <=0.8.27;

import {MockWallet} from "./mocks/MockWallet.sol";
import {MockWalletFactory} from "./mocks/MockWalletFactory.sol";

contract DeploySCWallet {
    MockWallet public mockWalletModule;
    MockWallet public scw;
    MockWalletFactory public scmf;
    address public scwAddress;

    function run(bytes32 salt) external returns (address, address) {
        scmf = new MockWalletFactory();
        mockWalletModule = new MockWallet();
        scmf.deploy(address(mockWalletModule), salt);
        scwAddress = scmf.getAddress(address(mockWalletModule), salt);
        scw = MockWallet(scwAddress);
        return (scwAddress, address(mockWalletModule));
    }
}
