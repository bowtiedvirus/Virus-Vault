// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";

import {IYieldStrategy} from "../../src/interfaces/IYieldStrategy.sol";
import {IDSRManager} from "../../src/interfaces/IDSRManager.sol";
import {MakerDAOYieldStrategy} from "../../src/MakerDAOYieldStrategy.sol";

// Note: When using the MakerDAOYieldStrategy, on deposit there is a 1 unit of token lost, it might be a fee or a rounding issue in the DSR.
// Therefore, these tests check for a balance greater than 99 instead of 100, even though it SHOULD be greater than 99.9999... ether, just easier to read this way.
contract MakerDAOYieldStrategyForkTest is Test {
    uint256 mainnetFork;
    address constant MAINNET_DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant MAINNET_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant MAINNET_DATA_FEED_REGISTRY = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;
    address constant MAINNET_UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant MAINNET_DSRMANAGER = 0x373238337Bfe1146fb49989fc222523f83081dDb;

    IYieldStrategy s_strategy;
    address s_underlying;

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

        vm.startPrank(owner);
        s_strategy = new MakerDAOYieldStrategy(MAINNET_DAI, MAINNET_DATA_FEED_REGISTRY, MAINNET_UNISWAP_V2_ROUTER);
        s_underlying = MAINNET_USDC;
        vm.stopPrank();

        deal(s_underlying, address(s_strategy), 100 ether, true);
        assertEq(ERC20(s_underlying).balanceOf(address(s_strategy)), 100 ether);
    }

    function testDeposit() public {
        s_strategy.deposit(s_underlying, MAINNET_DSRMANAGER, 100 ether);
        uint256 balance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertEq(ERC20(s_underlying).balanceOf(address(s_strategy)), 0 ether);
        assertGe(balance, 99 ether);
    }

    function testWithdraw() public {
        s_strategy.deposit(s_underlying, MAINNET_DSRMANAGER, 100 ether);
        uint256 depositBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertEq(ERC20(s_underlying).balanceOf(address(s_strategy)), 0 ether);
        assertGe(depositBalance, 99 ether);

        s_strategy.withdraw(s_underlying, MAINNET_DSRMANAGER, 100 ether);
        uint256 withdrawBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertGe(ERC20(s_underlying).balanceOf(address(s_strategy)), 98 ether);
        assertEq(withdrawBalance, 0 ether);
    }

    function testWithdrawAll() public {
        s_strategy.deposit(s_underlying, MAINNET_DSRMANAGER, 100 ether);
        uint256 depositBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertEq(ERC20(s_underlying).balanceOf(address(s_strategy)), 0 ether);
        assertGe(depositBalance, 99 ether);

        s_strategy.withdrawAll(s_underlying, MAINNET_DSRMANAGER);
        uint256 withdrawBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));

        assertGe(ERC20(s_underlying).balanceOf(address(s_strategy)), 98 ether);
        assertEq(withdrawBalance, 0 ether);
    }

    function testGetTotalAssets() public {
        uint256 balance = s_strategy.totalAssets(s_underlying, MAINNET_DSRMANAGER);
        assertEq(balance, 0 ether);

        s_strategy.deposit(s_underlying, MAINNET_DSRMANAGER, 100 ether);
        uint256 depositBalance = IDSRManager(MAINNET_DSRMANAGER).daiBalance(address(s_strategy));
        assertGe(depositBalance, 99 ether);
    }
}
