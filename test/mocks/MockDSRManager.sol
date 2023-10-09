// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {console2} from "forge-std/Test.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

contract MockDsrManager {
    function daiBalance(address usr) external returns (uint256 wad) {}

    function join(address dst, uint256 wad) external {}

    function exit(address dst, uint256 wad) external {}

    function exitAll(address dst) external {}
}
