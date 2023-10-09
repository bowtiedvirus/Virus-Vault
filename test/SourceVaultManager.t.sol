// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MockERC20} from "@solmate/src/test/utils/mocks/MockERC20.sol";

import "../src/SourceVaultManager.sol";
import {IYieldStrategy} from "../src/interfaces/IYieldStrategy.sol";
import {MockYieldStrategy, MockPool} from "./mocks/MockYieldStrategy.sol";
import {MockRouterClient} from "./mocks/MockRouterClient.sol";
import {Vault, StrategyParams} from "../src/Vault.sol";

contract SourceVaultManagerTest is Test {
    SourceVaultManager s_sourceVaultManager;
    uint256 s_mockFee;

    MockERC20 s_underlying;
    Vault s_vault;
    IYieldStrategy s_strategy;
    MockPool s_pool;

    address owner;
    address alice;
    address bob;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        s_underlying = new MockERC20("Mock Token", "TKN", 18);
        s_pool = new MockPool(s_underlying);

        vm.startPrank(owner);
        s_strategy = new MockYieldStrategy();
        s_vault =
        new Vault(s_underlying, "Mock Token Vault", "vwTKN", StrategyParams(s_strategy, address(s_pool)), address(0x0), payable(0x0));
        s_sourceVaultManager =
            new SourceVaultManager(address(new MockRouterClient()), address(0x1234), address(s_vault));
        s_vault.setSourceVaultManager(payable(s_sourceVaultManager));
        s_sourceVaultManager.setApprovedDestinationVaultManager(0, address(0x0));
        vm.stopPrank();

        vm.startPrank(address(s_vault));
        s_mockFee = s_sourceVaultManager.estimateFeeForSendShares(address(alice), 100 ether, 0, address(0x0));
        vm.stopPrank();
    }

    function testOnlyVaultCanCallSenderFunctions(uint256 amount) public {
        vm.assume(amount > s_mockFee);
        vm.deal(address(s_vault), amount);
        vm.deal(address(alice), amount);

        vm.startPrank(address(s_vault));
        s_sourceVaultManager.sendShares{value: amount}(address(0x0), 100 ether, 0, address(0x0), address(0x0));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        s_sourceVaultManager.sendShares{value: amount}(address(alice), 100 ether, 0, address(0x0), address(alice));
        vm.stopPrank();
    }

    function testOnlyOwnerCanSetApprovedDestinationVaultManager() public {
        vm.startPrank(owner);
        s_sourceVaultManager.setApprovedDestinationVaultManager(0, address(0x1));
        vm.stopPrank();

        assertEq(s_sourceVaultManager.approvedDestinationVaultManagers(0), address(0x1));
    }

    function testOnlyApprovedDestinationVaultManagersCanBeSentTo(uint64 chainId, address destinationVaultManager)
        public
    {
        vm.assume(chainId != 0);
        vm.assume(destinationVaultManager != address(0x0));

        vm.startPrank(address(s_vault));
        vm.expectRevert();
        s_sourceVaultManager.sendShares{value: 1 ether}(
            address(alice), 100 ether, chainId, destinationVaultManager, address(0x0)
        );
        vm.stopPrank();
    }

    function testSendNotEnoughFee() public {
        vm.startPrank(address(s_vault));
        vm.expectRevert();
        s_sourceVaultManager.sendShares(address(alice), 100 ether, 0, address(0x0), address(alice));
        vm.stopPrank();
    }

    function testExtraNativeFeeIsRefunded(uint256 amount) public {
        vm.assume(amount > s_mockFee);
        vm.deal(address(s_vault), amount);

        vm.startPrank(address(s_vault));
        s_sourceVaultManager.sendShares{value: amount}(address(alice), 100 ether, 0, address(0x0), address(alice));
        vm.stopPrank();

        assertEq(address(alice).balance, amount - s_mockFee);
    }

    function testFeeEstimateIsWhatWouldBePaidInSend() public {
        vm.startPrank(address(s_vault));
        uint256 fee = s_sourceVaultManager.estimateFeeForSendShares(address(alice), 100 ether, 0, address(0x0));
        vm.stopPrank();

        vm.deal(address(s_vault), fee);

        vm.startPrank(address(s_vault));
        s_sourceVaultManager.sendShares{value: fee}(address(alice), 100 ether, 0, address(0x0), address(alice));
        vm.stopPrank();

        assertEq(address(alice).balance, 0);
    }
}
