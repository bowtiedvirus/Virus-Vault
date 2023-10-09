// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/Test.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {
    Vault,
    StrategyParams,
    CouldNotWithdrawFromStrategy,
    CouldNotDepositToStrategy,
    CouldNotGetTotalAssetsFromStrategy
} from "../../src/Vault.sol";
import {IYieldStrategy} from "../../src/interfaces/IYieldStrategy.sol";
import {IDSRManager} from "../../src/interfaces/IDSRManager.sol";
import {MakerDAOYieldStrategy} from "../../src/MakerDAOYieldStrategy.sol";
import {MockYieldStrategy, MockPool} from "../mocks/MockYieldStrategy.sol";

// Note: When using the MakerDAOYieldStrategy, on deposit there is a 1 unit of token lost, it might be a fee or a rounding issue in the DSR.
// Therefore, these tests check for a balance greater than 99 instead of 100, even though it SHOULD be greater than 99.9999... ether, just easier to read this way.
contract VaultForkTest is Test {
    ERC20 s_underlying;
    Vault s_vault;
    IYieldStrategy s_strategy;
    address s_pool;

    uint256 mainnetFork;
    address constant MAINNET_DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant MAINNET_DSRMANAGER = 0x373238337Bfe1146fb49989fc222523f83081dDb;

    address owner;
    address alice;
    address bob;

    function setUp() public {
        string memory rpc_url = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createFork(rpc_url);
        vm.selectFork(mainnetFork);

        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        s_underlying = ERC20(MAINNET_DAI);
        s_pool = MAINNET_DSRMANAGER;

        vm.startPrank(owner);
        s_strategy = new MakerDAOYieldStrategy();
        s_vault = new Vault(s_underlying, "Mock Token Vault", "vwTKN", StrategyParams(s_strategy, s_pool));
        vm.stopPrank();

        deal(MAINNET_DAI, alice, 100 ether, true);
        deal(MAINNET_DAI, bob, 100 ether, true);
        assertEq(ERC20(MAINNET_DAI).balanceOf(alice), 100 ether);
        assertEq(ERC20(MAINNET_DAI).balanceOf(bob), 100 ether);
    }

    function testOnlyOwnerCanSetStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MakerDAOYieldStrategy();
        StrategyParams memory newStrategyParams = StrategyParams(newStrategy, s_pool);
        s_vault.setNewStrategy(newStrategyParams);
        vm.stopPrank();

        (IYieldStrategy implementation, address target) = s_vault.s_strategy();
        assertEq(address(implementation), address(newStrategy));
        assertEq(target, s_pool);
    }

    function testVaultCanDepositUnderlyingFromAliceToStrategy() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertGe(s_vault.s_totalAssetsInStrategy(), 99 ether);
    }

    function testVaultCanWithdrawFromStrategyAndBackToAlice() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertGe(s_vault.s_totalAssetsInStrategy(), 99 ether);

        vm.startPrank(alice);
        s_vault.withdraw(s_vault.s_totalAssetsInStrategy(), alice, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_vault.s_totalAssetsInStrategy(), 0 ether);
        assertGe(s_underlying.balanceOf(alice), 99 ether);
    }

    function testVaultMovesAssetsToNewStrategyWhenSet() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertGe(s_vault.s_totalAssetsInStrategy(), 99 ether);

        MockPool newPool = new MockPool(s_underlying);
        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MockYieldStrategy();
        StrategyParams memory newStrategyParams = StrategyParams(newStrategy, address(newPool));
        s_vault.setNewStrategy(newStrategyParams);
        vm.stopPrank();

        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertGe(newPool.s_balances(address(s_vault)), 99 ether);
        assertEq(IDSRManager(s_pool).daiBalance(address(s_vault)), 0 ether);
    }

    function testVaultTotalAssetsTracksUnderlyingAndStrategy() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertGe(s_vault.totalAssets(), 99 ether);
        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertGe(s_vault.s_totalAssetsInStrategy(), 99 ether);

        vm.startPrank(alice);
        s_vault.withdraw(s_vault.s_totalAssetsInStrategy(), alice, alice);
        vm.stopPrank();

        assertEq(s_vault.totalAssets(), 0 ether);
        assertEq(s_underlying.balanceOf(address(s_vault)), 0 ether);
        assertEq(s_vault.s_totalAssetsInStrategy(), 0 ether);
    }

    function testMaxRedeemAndMaxWithdrawAreTheSameValueForOwner() public {
        vm.startPrank(alice);
        s_underlying.approve(address(s_vault), 100 ether);
        s_vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertGe(s_vault.maxRedeem(alice), 99 ether);
        assertGe(s_vault.maxWithdraw(alice), 99 ether);
    }
}
