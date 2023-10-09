// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {FeedRegistryInterface} from "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

import {IYieldStrategy} from "./interfaces/IYieldStrategy.sol";
import {IDSRManager} from "./interfaces/IDSRManager.sol";

// This will be used as an "implementation" for the YieldStrategy by delegatecall.
contract MakerDAOYieldStrategy is IYieldStrategy {
    address public immutable i_daiAddress;
    FeedRegistryInterface internal immutable i_dataFeedRegistry;
    IUniswapV2Router02 internal immutable i_uniswapRouter;

    event DaiBalance(address indexed src, uint256 balance);

    constructor(
        address underlyingAsset,
        address target,
        address daiAddress,
        address dataFeedRegistry,
        address uniswapRouter
    ) IYieldStrategy(underlyingAsset, target) {
        i_daiAddress = daiAddress;
        i_dataFeedRegistry = FeedRegistryInterface(dataFeedRegistry);
        i_uniswapRouter = IUniswapV2Router02(uniswapRouter);
    }

    function deposit(uint256 amount) external override {
        // Want to know something weird? Forge coverage won't track this file if I remove this console.log! Awesum!
        console2.log("");
        uint256 daiAmount = amount;
        // Swap to DAI if underlying is not DAI
        if (i_underlyingAsset != i_daiAddress) {
            (int256 underlyingEthPrice, int256 daiEthPrice) = getUnderlyingAndDaiEthPrices();
            daiAmount = amount * uint256(daiEthPrice) / uint256(underlyingEthPrice); // Assumes it is token per ETH in the unit conversion

            require(ERC20(i_underlyingAsset).approve(address(i_uniswapRouter), amount), "approve failed.");
            address[] memory path = makeSimpleSwapPath(i_underlyingAsset, i_daiAddress);
            IUniswapV2Router02(i_uniswapRouter).swapExactTokensForTokens(
                amount, 0, path, address(this), block.timestamp
            );
        }

        daiAmount = ERC20(i_daiAddress).balanceOf(address(this));

        IDSRManager dsrM = IDSRManager(i_target);
        ERC20(i_daiAddress).approve(address(dsrM), daiAmount);
        dsrM.join(address(this), daiAmount);
    }

    function withdraw(uint256 amount) external override {
        // Normalize ERC with non-standard decimals to get the units up to speed with what was returned by uniswap
        amount *= 10 ** (18 - ERC20(i_underlyingAsset).decimals());

        uint256 daiAmount = amount;
        if (i_underlyingAsset != i_daiAddress) {
            (int256 underlyingEthPrice, int256 daiEthPrice) = getUnderlyingAndDaiEthPrices();
            daiAmount = amount * uint256(daiEthPrice) / uint256(underlyingEthPrice); // Assumes it is token per ETH in the unit conversion
        }

        IDSRManager dsrM = IDSRManager(i_target);
        uint256 daiBalance = dsrM.daiBalance(address(this));
        if (daiAmount > daiBalance) {
            daiAmount = daiBalance;
        }
        dsrM.exit(address(this), daiAmount);

        if (i_underlyingAsset != i_daiAddress) {
            require(ERC20(i_daiAddress).approve(address(i_uniswapRouter), daiAmount), "approve failed.");
            address[] memory path = makeSimpleSwapPath(i_daiAddress, i_underlyingAsset);

            // Open to sandwich attacks, but hard to exploit with high liquidity pairs (e.g. DAI/USDC)
            IUniswapV2Router02(i_uniswapRouter).swapExactTokensForTokens(
                daiAmount, 0, path, address(this), block.timestamp
            );
        }
    }

    function withdrawAll() external override {
        IDSRManager dsrM = IDSRManager(i_target);
        dsrM.exitAll(address(this));

        uint256 daiAmount = ERC20(i_daiAddress).balanceOf(address(this));

        if (i_underlyingAsset != i_daiAddress) {
            require(ERC20(i_daiAddress).approve(address(i_uniswapRouter), daiAmount), "approve failed.");
            address[] memory path = makeSimpleSwapPath(i_daiAddress, i_underlyingAsset);

            IUniswapV2Router02(i_uniswapRouter).swapExactTokensForTokens(
                daiAmount, 0, path, address(this), block.timestamp
            );
        }
    }

    function totalAssets() external override returns (uint256) {
        IDSRManager dsrM = IDSRManager(i_target);
        uint256 balance = dsrM.daiBalance(address(this));
        emit DaiBalance(address(this), balance);

        if (i_underlyingAsset != i_daiAddress) {
            (int256 underlyingEthPrice, int256 daiEthPrice) = getUnderlyingAndDaiEthPrices();
            uint256 underlyingAmount = balance * uint256(underlyingEthPrice) / uint256(daiEthPrice);
            return underlyingAmount;
        }

        return balance;
    }

    function getUnderlyingAndDaiEthPrices() internal view returns (int256 underlyingEthPrice, int256 daiEthPrice) {
        underlyingEthPrice = getEthPrice(i_underlyingAsset);
        daiEthPrice = getEthPrice(i_daiAddress);
    }

    function makeSimpleSwapPath(address from, address to) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        return path;
    }

    /*//////////////////////////////////////////////////////////////
                          Price Feed Logic
    //////////////////////////////////////////////////////////////*/

    function getEthPrice(address asset) public view returns (int256) {
        (
            /*uint80 roundID*/
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = i_dataFeedRegistry.latestRoundData(asset, Denominations.ETH);
        return price;
    }
}
