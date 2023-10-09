// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";

interface DsrManager {
    function daiBalance(address usr) external returns (uint256 wad);
    function join(address dst, uint256 wad) external;
    function exit(address dst, uint256 wad) external;
    function exitAll(address dst) external;
}

interface GemLike {
    function transferFrom(address,address,uint) external returns (bool);
    function approve(address,uint) external returns (bool);
}

// This will be used as an "implementation" for the YieldStrategy by delegatecall.
contract MakerDAOYieldStrategy is IYieldStrategy {
    event DaiBalance(address indexed src, uint balance);

    function deposit(address underlying_asset, address target, uint256 amount) external override {
        ERC20 daiToken = ERC20(underlying_asset);
        DsrManager dsrM = DsrManager(target);

        daiToken.transferFrom(msg.sender, address(this), amount);
        dsrM.join(address(this), amount);
    }

    function withdraw(address, address target, uint256 amount) external override {
        DsrManager dsrM = DsrManager(target);
        dsrM.exit(address(this), amount);
    }

    function totalAssets(address, address target) external override returns (uint256) {
        DsrManager dsrM = DsrManager(target);
        uint balance = dsrM.daiBalance(address(this));
        emit DaiBalance(address(this), balance);
        return balance;
    }
}