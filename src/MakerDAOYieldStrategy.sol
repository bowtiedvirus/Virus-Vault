// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";
import {IDSRManager} from "./interfaces/IDSRManager.sol";

// This will be used as an "implementation" for the YieldStrategy by delegatecall.
contract MakerDAOYieldStrategy is IYieldStrategy {
    event DaiBalance(address indexed src, uint256 balance);

    function deposit(address underlying_asset, address target, uint256 amount) external override {
        ERC20 daiToken = ERC20(underlying_asset);
        IDSRManager dsrM = IDSRManager(target);

        daiToken.approve(address(dsrM), amount);
        dsrM.join(address(this), amount);
    }

    function withdraw(address, address target, uint256 amount) external override {
        IDSRManager dsrM = IDSRManager(target);
        dsrM.exit(address(this), amount);
    }

    function withdrawAll(address, address target) external override {
        IDSRManager dsrM = IDSRManager(target);
        dsrM.exitAll(address(this));
    }

    function totalAssets(address, address target) external override returns (uint256) {
        IDSRManager dsrM = IDSRManager(target);
        uint256 balance = dsrM.daiBalance(address(this));
        emit DaiBalance(address(this), balance);
        return balance;
    }
}
