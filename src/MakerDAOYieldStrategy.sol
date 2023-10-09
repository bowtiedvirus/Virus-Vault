// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";

// This will be used as an "implementation" for the YieldStrategy by delegatecall.
contract MakerDAOYieldStrategy is IYieldStrategy {
    function deposit(address underlying_asset, address target, uint256 amount) external override returns (bool) {}

    function withdraw(address underlying_asset, address target, uint256 amount) external override returns (bool) {}

    function totalAssets(address underlying_asset, address target) external view override returns (uint256) {}
}
