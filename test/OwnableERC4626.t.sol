// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {DSTestPlus} from "@solmate/src/test/utils/DSTestPlus.sol";
import {Test} from "forge-std/Test.sol";

import {MockERC20} from "@solmate/src/test/utils/mocks/MockERC20.sol";
import {OwnableERC4626} from "../src/OwnableERC4626.sol";
import {IYieldStrategy} from "../src/interfaces/IYieldStrategy.sol";
import {MockYieldStrategy, MockLP} from "./mocks/MockYieldStrategy.sol";


contract OwnableERC4626Test is Test {
    MockERC20 s_underlying;
    OwnableERC4626 s_vault;
    IYieldStrategy s_strategy;
    MockLP s_lp;

    address owner;
    address alice;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");

        vm.startPrank(owner);
        s_underlying = new MockERC20("Mock Token", "TKN", 18);
        s_lp = new MockLP(s_underlying);
        s_strategy = new MockYieldStrategy(s_underlying, s_lp);
        s_vault = new OwnableERC4626(s_underlying, "Mock Token Vault", "vwTKN", s_strategy);
        vm.stopPrank();
    }

    function testOnlyOwnerCanSetStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MockYieldStrategy(s_underlying, s_lp);
        s_vault.setNewStrategy(newStrategy);
        vm.stopPrank();

        assertEq(address(s_vault.s_yieldStrategy()), address(newStrategy));
    }

    function testNonOwnerUnableToSetStrategy() public {
        vm.startPrank(owner);
        IYieldStrategy newStrategy = new MockYieldStrategy(s_underlying, s_lp);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        s_vault.setNewStrategy(newStrategy);
        vm.stopPrank();
    }

    
}
