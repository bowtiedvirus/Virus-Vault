// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

interface IYieldStrategy {  
    function deposit(uint256 amount) external returns(bool);  
    function withdraw(uint256 amount) external returns(bool);  
}
