// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";


import {IYieldStrategy} from "../../src/interfaces/IYieldStrategy.sol";


// This will be used as an "implementation" for the YieldStrategy by delegatecall. 
contract MockYieldStrategy is IYieldStrategy {
    using SafeTransferLib for ERC20;

    ERC20 public immutable si_underlying;
    MockLP public immutable si_lp;

    constructor(ERC20 underlying, MockLP lp) {
        si_underlying = underlying;
        si_lp = lp;
    }

    function deposit(uint256 amount) external override returns (bool) {
        address lpAddress = address(si_lp);
        si_underlying.safeApprove(lpAddress, amount);
        return true;
    }

    function withdraw(uint256 amount) external override returns (bool) {
        si_lp.withdraw(amount);
        return true;
    }
}

contract MockLP {
    using SafeTransferLib for ERC20;

    ERC20 public s_underlying;

    constructor(ERC20 underlying) {
        s_underlying = underlying;
    }

    function deposit(uint256 amount) external {
        s_underlying.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        s_underlying.safeTransfer(msg.sender, amount);
    }
}