// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

contract MockDsrManager {
    // @note Put this here to make forge coverage not track the coverage of this contract.
    // https://github.com/foundry-rs/foundry/issues/2988
    function test() public {}

    function daiBalance(address usr) external returns (uint256 wad) {}

    function join(address dst, uint256 wad) external {}

    function exit(address dst, uint256 wad) external {}

    function exitAll(address dst) external {}
}
