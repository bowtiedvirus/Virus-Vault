// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {console2} from "forge-std/Test.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

import {IYieldStrategy} from "../../src/interfaces/IYieldStrategy.sol";

// This will be used as an "implementation" for the YieldStrategy by delegatecall.
contract MockYieldStrategy is IYieldStrategy {
    using SafeTransferLib for ERC20;

    function deposit(address underlying_asset, address target, uint256 amount) external override returns (bool) {
        ERC20(underlying_asset).safeApprove(target, amount);
        MockPool(target).stake(amount);
        return true;
    }

    function withdraw(address, /* underlying_asset */ address target, uint256 amount) external override returns (bool) {
        MockPool(target).unstake(amount);
        return true;
    }

    function totalAssets(address, /* underlying_asset */ address target) external view override returns (uint256) {
        return MockPool(target).s_balances(address(this));
    }
}

contract MockYieldStrategyBadDeposit is IYieldStrategy {
    using SafeTransferLib for ERC20;

    function deposit(address, address, uint256) external pure override returns (bool) {
        revert();
    }

    function withdraw(address, address, uint256) external pure override returns (bool) {
        revert();
    }

    function totalAssets(address, address) external pure override returns (uint256) {
        revert();
    }
}

contract MockYieldStrategyBadTotalAssets is IYieldStrategy {
    using SafeTransferLib for ERC20;

    function deposit(address, address, uint256) external pure override returns (bool) {
        return true;
    }

    function withdraw(address, address, uint256) external pure override returns (bool) {
        revert();
    }

    function totalAssets(address, address) external pure override returns (uint256) {
        revert();
    }
}

contract MockYieldStrategyBadWithdraw is IYieldStrategy {
    using SafeTransferLib for ERC20;

    function deposit(address, address, uint256) external pure override returns (bool) {
        return true;
    }

    function withdraw(address, address, uint256) external pure override returns (bool) {
        revert();
    }

    function totalAssets(address, address) external pure override returns (uint256) {
        return 0;
    }
}

contract MockPool {
    using SafeTransferLib for ERC20;

    ERC20 public s_underlying;
    mapping(address => uint256) public s_balances;

    constructor(ERC20 underlying) {
        s_underlying = underlying;
    }

    function stake(uint256 amount) external {
        s_balances[msg.sender] += amount;
        s_underlying.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {
        require(s_balances[msg.sender] >= amount, "MockPool: insufficient balance");
        s_balances[msg.sender] -= amount;
        s_underlying.safeTransfer(msg.sender, amount);
    }
}
