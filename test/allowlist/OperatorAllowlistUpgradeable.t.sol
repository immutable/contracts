pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {MockOperatorAllowlistUpgradeable} from "../../contracts/mocks/MockOAL.sol";
import {ImmutableERC721} from "../../contracts/token/erc721/preset/ImmutableERC721.sol";
import {DeployOperatorAllowlist} from  "../utils/DeployAllowlistProxy.sol";


contract OperatorAllowlistTest is Test {
    OperatorAllowlistUpgradeable public allowlist;
    ImmutableERC721 public immutableERC721;
    MockOperatorAllowlistUpgradeable public oalV2;
    
    uint256 adminPrivateKey = 1;
    uint256 upgraderPrivateKey = 2;
    uint256 registerarPrivateKey = 3;
    uint256 feeReceiverKey = 4;

    address admin = vm.addr(adminPrivateKey);
    address upgrader = vm.addr(upgraderPrivateKey);
    address registerar = vm.addr(registerarPrivateKey);
    address feeReceiver = vm.addr(feeReceiverKey);
    address proxyAddr;
    

    function setUp() public {
        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        proxyAddr = deployScript.run(admin, upgrader);

        allowlist = OperatorAllowlistUpgradeable(proxyAddr);
        vm.startPrank(admin);
        allowlist.grantRegistrarRole(registerar);
        vm.stopPrank();

        immutableERC721 = new ImmutableERC721(
            admin,
            "test",
            "USDC",
            "test-base-uri",
            "test-contract-uri",
            address(allowlist),
            feeReceiver,
            0
        );
    }

    function testDeployment() public {
        assertTrue(allowlist.hasRole(allowlist.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(allowlist.hasRole(allowlist.REGISTRAR_ROLE(), registerar));
        assertTrue(allowlist.hasRole(allowlist.UPGRADE_ROLE(), upgrader));
        assertEq(address(immutableERC721.operatorAllowlist()), proxyAddr);
    }

    function testUpgradeToV2() public {
        MockOperatorAllowlistUpgradeable oalImplV2 = new MockOperatorAllowlistUpgradeable();

        vm.prank(upgrader);
        allowlist.upgradeToAndCall(address(oalImplV2), abi.encodeWithSelector(oalImplV2.setMockValue.selector, 50));

        oalV2 = MockOperatorAllowlistUpgradeable(proxyAddr);

        uint256 mockVal = oalV2.mockInt();
        assertEq(mockVal, 50);
    }
}