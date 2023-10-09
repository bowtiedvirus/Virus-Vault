// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/mixins/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";

error CouldNotWithdrawFromStrategy(address sender, address asset, address yieldStrategyTarget, uint256 amount);
error CouldNotDepositToStrategy(address sender, address asset, address yieldStrategyTarget, uint256 amount);
error CouldNotGetTotalAssetsFromStrategy(address asset, address yieldStrategyTarget);

struct StrategyParams {
    IYieldStrategy implementation;
    address target;
}

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Forked from Solmate ERC4626 (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
contract Vault is ERC4626, Ownable {
    StrategyParams public s_strategy;

    uint256 public s_totalAssetsInStrategy;

    /*//////////////////////////////////////////////////////////////
                          EVENTS
    //////////////////////////////////////////////////////////////*/
    event StrategyDeposit(IYieldStrategy strategy, uint256 amount);
    event StrategyWithdrawal(IYieldStrategy strategy, uint256 amount);

    constructor(ERC20 _asset, string memory _name, string memory _symbol, StrategyParams memory strategy)
        ERC4626(_asset, _name, _symbol)
        Ownable()
    {
        s_strategy = strategy;
        s_totalAssetsInStrategy = 0;
    }

    // @dev Tracks assets owned by the vault plus assets in the strategy.
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)) + s_totalAssetsInStrategy;
    }

    /*//////////////////////////////////////////////////////////////
                          Internal Hooks Logic
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal override after_updateTotalAssetsInStrategy {
        _withdrawFromStrategy(assets);
        // Could do s_totalAssetsInStrategy -= assets instead? Could be more gas efficient
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal override after_updateTotalAssetsInStrategy {
        _depositToStrategy(assets);
        // Could do s_totalAssetsInStrategy += assets instead? Could be more gas efficient
    }

    /*//////////////////////////////////////////////////////////////
                          Yield Strategy Logic
    //////////////////////////////////////////////////////////////*/

    modifier after_updateTotalAssetsInStrategy() {
        _;
        s_totalAssetsInStrategy = _getTotalAssetsInStrategy();
    }

    function setNewStrategy(StrategyParams memory newStrategy) external onlyOwner after_updateTotalAssetsInStrategy {
        _withdrawFromStrategy(s_totalAssetsInStrategy);

        s_strategy = newStrategy;

        _depositToStrategy(s_totalAssetsInStrategy);
    }

    function _withdrawFromStrategy(uint256 amount) internal {
        address yieldStrategyAddress = address(s_strategy.implementation);
        bytes memory withdrawCalldata =
            abi.encodeWithSignature("withdraw(address,address,uint256)", address(asset), s_strategy.target, amount);

        (bool success,) = yieldStrategyAddress.delegatecall(withdrawCalldata);
        if (!success) {
            revert CouldNotWithdrawFromStrategy(msg.sender, address(asset), s_strategy.target, amount);
        }

        emit StrategyWithdrawal(s_strategy.implementation, amount);
    }

    function _depositToStrategy(uint256 amount) internal {
        address yieldStrategyAddress = address(s_strategy.implementation);
        bytes memory depositCalldata =
            abi.encodeWithSignature("deposit(address,address,uint256)", address(asset), s_strategy.target, amount);

        (bool success,) = yieldStrategyAddress.delegatecall(depositCalldata);
        if (!success) {
            revert CouldNotDepositToStrategy(msg.sender, address(asset), s_strategy.target, amount);
        }

        emit StrategyDeposit(s_strategy.implementation, amount);
    }

    function _getTotalAssetsInStrategy() internal returns (uint256) {
        address yieldStrategyAddress = address(s_strategy.implementation);
        bytes memory totalAssetsCalldata =
            abi.encodeWithSignature("totalAssets(address,address)", address(asset), s_strategy.target);

        (bool success, bytes memory retData) = yieldStrategyAddress.delegatecall(totalAssetsCalldata);
        if (!success) {
            revert CouldNotGetTotalAssetsFromStrategy(address(asset), s_strategy.target);
        }

        return abi.decode(retData, (uint256));
    }

    // @dev just in case this contract receives ETH accidentally
    function gatherDust() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
