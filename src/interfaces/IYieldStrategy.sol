// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

// @dev Should not hold any state, as it will be delegatecalled by the vault. Adding state is risky.
abstract contract IYieldStrategy {
    address public immutable i_underlyingAsset;
    address public immutable i_target;

    constructor(address underlyingAsset, address target) {
        i_underlyingAsset = underlyingAsset;
        i_target = target;
    }

    function deposit(uint256 amount) external virtual;
    function withdraw(uint256 amount) external virtual;
    function withdrawAll() external virtual;
    function totalAssets() external virtual returns (uint256);
}
