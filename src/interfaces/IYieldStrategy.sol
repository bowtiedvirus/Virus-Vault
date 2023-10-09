// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

// @dev Should not hold any state, as it will be delegatecalled by the vault. Adding state is risky.
interface IYieldStrategy {
    function deposit(address underlying_asset, address target, uint256 amount) external returns (bool);
    function withdraw(address underlying_asset, address target, uint256 amount) external returns (bool);
    function totalAssets(address underlying_asset, address target) external view returns (uint256);
}
