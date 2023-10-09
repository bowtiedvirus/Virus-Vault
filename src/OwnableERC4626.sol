// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ERC4626} from "@solmate/src/mixins/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";


/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Forked from Solmate ERC4626 (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
contract OwnableERC4626 is ERC4626, Ownable {
    IYieldStrategy public s_yieldStrategy;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        IYieldStrategy yieldStrategy
    ) ERC4626(_asset, _name, _symbol) Ownable() {
        s_yieldStrategy = yieldStrategy;
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 /*shares*/) internal override {
        address yieldStrategyAddress = address(s_yieldStrategy);
        bytes memory withdrawCalldata = abi.encodeWithSignature("withdraw(uint256)", assets);

        (bool success, ) = yieldStrategyAddress.delegatecall(withdrawCalldata);
        require(success, "Delegate call failed");
    }

    function afterDeposit(uint256 assets, uint256 /*shares*/) internal override {
        address yieldStrategyAddress = address(s_yieldStrategy);
        bytes memory depositCalldata = abi.encodeWithSignature("deposit(uint256)", assets);

        (bool success, ) = yieldStrategyAddress.delegatecall(depositCalldata);
        require(success, "Delegate call failed");
    }
}
