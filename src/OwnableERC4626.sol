// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/mixins/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";

error CouldNotWithdrawFromStrategy(); // TODO: Add fields to these errors
error CouldNotDepositToStrategy();
error CouldNotGetTotalAssetsFromStrategy();

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Forked from Solmate ERC4626 (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
contract OwnableERC4626 is ERC4626, Ownable {
    IYieldStrategy public s_yieldStrategyImplementation;
    address public s_yieldStrategyTarget;

    uint256 public s_grossBalance;

    /*//////////////////////////////////////////////////////////////
                          EVENTS
    //////////////////////////////////////////////////////////////*/
    event StrategyDeposit(IYieldStrategy strategy, uint256 amount);
    event StrategyWithdrawal(IYieldStrategy strategy, uint256 amount);

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        IYieldStrategy yieldStrategy,
        address strategyTarget
    ) ERC4626(_asset, _name, _symbol) Ownable() {
        s_yieldStrategyImplementation = yieldStrategy;
        s_yieldStrategyTarget = strategyTarget;
        s_grossBalance = 0;
    }

    function totalAssets() public view override returns (uint256) {
        return s_grossBalance;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 /*shares*/ ) internal override {
        s_grossBalance -= assets;
        _withdrawFromStrategy(assets);
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/ ) internal override {
        s_grossBalance += assets;
        _depositToStrategy(assets);
    }

    function setNewStrategy(IYieldStrategy newStrategyImplementation, address strategyTarget) external onlyOwner {
        // _withdrawFromStrategy(totalAssets());

        s_yieldStrategyImplementation = newStrategyImplementation;
        s_yieldStrategyTarget = strategyTarget;
    }

    function _withdrawFromStrategy(uint256 amount) internal {
        address yieldStrategyAddress = address(s_yieldStrategyImplementation);
        bytes memory withdrawCalldata =
            abi.encodeWithSignature("withdraw(address,address,uint256)", address(asset), s_yieldStrategyTarget, amount);

        (bool success,) = yieldStrategyAddress.delegatecall(withdrawCalldata);
        if (!success) {
            revert CouldNotWithdrawFromStrategy();
        }

        emit StrategyWithdrawal(s_yieldStrategyImplementation, amount);
    }

    function _depositToStrategy(uint256 amount) internal {
        address yieldStrategyAddress = address(s_yieldStrategyImplementation);
        bytes memory depositCalldata =
            abi.encodeWithSignature("deposit(address,address,uint256)", address(asset), s_yieldStrategyTarget, amount);

        (bool success,) = yieldStrategyAddress.delegatecall(depositCalldata);
        if (!success) {
            revert CouldNotDepositToStrategy();
        }

        emit StrategyDeposit(s_yieldStrategyImplementation, amount);
    }
    
    function _totalAssetsInStrategy() internal returns (uint256) {
        address yieldStrategyAddress = address(s_yieldStrategyImplementation);
        bytes memory totalAssetsCalldata =
            abi.encodeWithSignature("totalAssets(address,address)", address(asset), s_yieldStrategyTarget);

        (bool success, bytes memory retData) = yieldStrategyAddress.delegatecall(totalAssetsCalldata);
        if (!success) {
            revert CouldNotGetTotalAssetsFromStrategy();
        }

        return abi.decode(retData, (uint256));
    }

    // @dev just in case this contract receives ETH accidentally
    function gatherDust() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
