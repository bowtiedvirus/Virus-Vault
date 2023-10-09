// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/Test.sol";

import {MockERC20} from "@solmate/src/test/utils/mocks/MockERC20.sol";
import {Vault} from "../src/Vault.sol";
import {
    CouldNotWithdrawFromStrategy,
    CouldNotDepositToStrategy,
    CouldNotGetTotalAssetsFromStrategy
} from "../src/Vault.sol";
import {IYieldStrategy} from "../src/interfaces/IYieldStrategy.sol";
import {
    MockYieldStrategy,
    MockPool,
    MockYieldStrategyBadDeposit,
    MockYieldStrategyBadTotalAssets,
    MockYieldStrategyBadWithdraw
} from "./mocks/MockYieldStrategy.sol";

contract OwnableERC4626Test is Test {
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
        s_vault = new Vault(s_underlying, "Mock Token Vault", "vwTKN", s_strategy, address(s_pool));
        vm.stopPrank();

        s_underlying.mint(address(s_pool), 1000 ether);
        s_underlying.mint(alice, 100 ether);
        s_underlying.mint(bob, 100 ether);
    }

    function testOnlyOwnerCanSetStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MockYieldStrategy();
        s_vault.setNewStrategy(newStrategy, address(s_pool));
        vm.stopPrank();

        assertEq(address(s_vault.s_yieldStrategyImplementation()), address(newStrategy));
    }

    function testNonOwnerUnableToSetStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MockYieldStrategy();
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        s_vault.setNewStrategy(newStrategy, address(s_pool));
        vm.stopPrank();
    }

    function testVaultCanDepositUnderlyingFromAliceToStrategy() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 100 ether);
    }

    function testVaultCanWithdrawFromStrategyAndBackToAlice() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 100 ether);

        vm.startPrank(alice);
        s_vault.withdraw(100 ether, alice, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 0 ether);
        assertEq(s_underlying.balanceOf(alice), 100 ether);
    }

    function testYieldStrategyWithBadDepositIsRejectedBySetNewStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy badStrategy = new MockYieldStrategyBadDeposit();

        // If this strategy is bad (reverts on deposit), the vault will also revert when depositing to the new strategy target.
        vm.expectRevert(
            abi.encodeWithSelector(CouldNotDepositToStrategy.selector, owner, address(s_underlying), address(s_pool), 0)
        );
        s_vault.setNewStrategy(badStrategy, address(s_pool));
        vm.stopPrank();
    }

    function testYieldStrategyWithBadTotalAssetsIsRejectedBySetNewStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy badStrategy = new MockYieldStrategyBadTotalAssets();

        // If this strategy is bad (reverts on totalAssets), the vault will also revert when re-calculating totalAssets.
        vm.expectRevert(
            abi.encodeWithSelector(CouldNotGetTotalAssetsFromStrategy.selector, address(s_underlying), address(s_pool))
        );
        s_vault.setNewStrategy(badStrategy, address(s_pool));
        vm.stopPrank();
    }

    function testYieldStrategyWithBadWithdraw() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        vm.startPrank(owner);
        IYieldStrategy badStrategy = new MockYieldStrategyBadWithdraw();
        s_vault.setNewStrategy(badStrategy, address(s_pool));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                CouldNotWithdrawFromStrategy.selector, alice, address(s_underlying), address(s_pool), 100 ether
            )
        );
        s_vault.withdraw(100 ether, alice, alice);
        vm.stopPrank();
    }

    function testVaultMovesAssetsToNewStrategyWhenSet() public {
        MockPool newPool = new MockPool(s_underlying);

        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 100 ether);

        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MockYieldStrategy();
        s_vault.setNewStrategy(newStrategy, address(newPool));
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(newPool.s_balances(address(s_vault)), 100 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 0 ether);
    }

    function testVaultTotalAssetsTracksUnderlyingAndStrategy() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_vault.totalAssets(), 100 ether);
        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 100 ether);

        vm.startPrank(alice);
        s_vault.withdraw(100 ether, alice, alice);
        vm.stopPrank();

        assertEq(s_vault.totalAssets(), 0 ether);
        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_pool.s_balances(address(s_vault)), 0 ether);
    }

    function testMaxRedeemAndMaxWithdrawAreTheSameValueForOwner() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_vault.maxRedeem(alice), 100 ether);
        assertEq(s_vault.maxWithdraw(alice), 100 ether);
    }

    function testGatherDust() public {
        vm.deal(address(s_vault), 100 ether);

        vm.prank(owner);
        s_vault.gatherDust();

        assertEq(owner.balance, 100 ether);
    }
}
