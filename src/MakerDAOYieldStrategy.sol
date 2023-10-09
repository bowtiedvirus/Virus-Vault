// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {OwnableERC4626} from "./OwnableERC4626.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";


// This will be used as an "implementation" for the YieldStrategy by delegatecall. 
abstract contract MakerDAOYieldStrategy is IYieldStrategy {    
    constructor() {}
}