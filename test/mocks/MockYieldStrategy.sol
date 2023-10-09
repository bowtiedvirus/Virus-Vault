// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

import {IYieldStrategy} from "../../src/interfaces/IYieldStrategy.sol";

// This will be used as an "implementation" for the YieldStrategy by delegatecall.
contract MockYieldStrategy is IYieldStrategy {
    using SafeTransferLib for ERC20;

    // @note Put this here to make forge coverage not track the coverage of this contract.
    // https://github.com/foundry-rs/foundry/issues/2988
    function test() public {}

    function deposit(address underlying_asset, address target, uint256 amount) public override {
        ERC20(underlying_asset).safeApprove(target, amount);
        MockPool(target).stake(amount);
    }

    function withdraw(address, address target, uint256 amount) public override {
        MockPool(target).unstake(amount);
    }

    function withdrawAll(address, address target) public override {
        MockPool(target).unstake(totalAssets(address(this), target));
    }

    function totalAssets(address, address target) public view override returns (uint256) {
        return MockPool(target).s_balances(address(this));
    }
}

contract MockYieldStrategyBadDeposit is IYieldStrategy {
    using SafeTransferLib for ERC20;

    // @note Put this here to make forge coverage not track the coverage of this contract.
    // https://github.com/foundry-rs/foundry/issues/2988
    function test() public {}

    function deposit(address, address, uint256) external pure override {
        revert();
    }

    function withdraw(address, address, uint256) external pure override {
        revert();
    }

    function withdrawAll(address, address) external pure override {
        revert();
    }

    function totalAssets(address, address) external pure override returns (uint256) {
        revert();
    }
}

contract MockYieldStrategyBadTotalAssets is IYieldStrategy {
    using SafeTransferLib for ERC20;

    // @note Put this here to make forge coverage not track the coverage of this contract.
    // https://github.com/foundry-rs/foundry/issues/2988
    function test() public {}

    function deposit(address, address, uint256) external pure override {}

    function withdraw(address, address, uint256) external pure override {
        revert();
    }

    function withdrawAll(address, address) external pure override {
        revert();
    }

    function totalAssets(address, address) external pure override returns (uint256) {
        revert();
    }
}

contract MockYieldStrategyBadWithdraw is IYieldStrategy {
    using SafeTransferLib for ERC20;

    // @note Put this here to make forge coverage not track the coverage of this contract.
    // https://github.com/foundry-rs/foundry/issues/2988
    function test() public {}

    function deposit(address, address, uint256) external pure override {}

    function withdraw(address, address, uint256) external pure override {
        revert();
    }

    function withdrawAll(address, address) external pure override {
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

    // @note Put this here to make forge coverage not track the coverage of this contract.
    // https://github.com/foundry-rs/foundry/issues/2988
    function test() public {}

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
