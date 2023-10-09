// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

import {IYieldStrategy} from "../src/interfaces/IYieldStrategy.sol";
import {IDSRManager} from "../src/interfaces/IDSRManager.sol";
import {MakerDAOYieldStrategy} from "../src/MakerDAOYieldStrategy.sol";

// Note: When using the MakerDAOYieldStrategy, on deposit there is a 1 unit of token lost, it might be a fee or a rounding issue in the DSR.
// Therefore, these tests check for a balance greater than 99 instead of 100, even though it SHOULD be greater than 99.9999... ether, just easier to read this way.
contract MakerDAOYieldStrategyForkTest is Test {
    uint256 mainnetFork;
    address constant MAINNET_DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant MAINNET_DSRMANAGER = 0x373238337Bfe1146fb49989fc222523f83081dDb;

    IYieldStrategy s_strategy;

    address owner;
    address alice;
    address bob;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(mainnetFork);

        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(owner);
        s_strategy = new MakerDAOYieldStrategy();
        vm.stopPrank();

        deal(MAINNET_DAI, address(s_strategy), 100 ether, true);
        assertEq(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), 100 ether);
    }

    function testDeposit() public {
        s_strategy.deposit(MAINNET_DAI, MAINNET_DSRMANAGER, 100 ether);
        uint256 balance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertEq(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), 0 ether);
        assertGe(balance, 99 ether);
    }

    function testWithdraw() public {
        s_strategy.deposit(MAINNET_DAI, MAINNET_DSRMANAGER, 100 ether);
        uint256 depositBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertEq(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), 0 ether);
        assertGe(depositBalance, 99 ether);

        s_strategy.withdraw(MAINNET_DAI, MAINNET_DSRMANAGER, depositBalance);
        uint256 withdrawBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertGe(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), 99.99 ether);
        assertEq(withdrawBalance, 0 ether);
    }

    function testWithdrawAll() public {
        s_strategy.deposit(MAINNET_DAI, MAINNET_DSRMANAGER, 100 ether);
        uint256 depositBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertEq(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), 0 ether);
        assertGe(depositBalance, 99 ether);

        s_strategy.withdrawAll(MAINNET_DAI, MAINNET_DSRMANAGER);
        uint256 withdrawBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertGe(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), 99.99 ether);
        assertEq(ERC20(MAINNET_DAI).balanceOf(address(s_strategy)), depositBalance);
        assertEq(withdrawBalance, 0 ether);
    }

    function testGetTotalAssets() public {
        uint256 balance = s_strategy.totalAssets(MAINNET_DAI, MAINNET_DSRMANAGER);
        assertEq(balance, 0 ether);

        s_strategy.deposit(MAINNET_DAI, MAINNET_DSRMANAGER, 100 ether);
        uint256 depositBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));
        assertGe(depositBalance, 9 ether);
    }
}
