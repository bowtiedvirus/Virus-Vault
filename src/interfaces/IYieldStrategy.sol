// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

interface IYieldStrategy {  
    function deposit() external returns(bool);  
    function withdraw() external returns(bool);  
}
