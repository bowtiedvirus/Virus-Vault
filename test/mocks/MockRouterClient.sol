// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract MockRouterClient is IRouterClient {
    function test() public {}

    function isChainSupported(uint64) external pure override returns (bool) {
        return true;
    }

    function getSupportedTokens(uint64) external pure override returns (address[] memory) {
        return new address[](0);
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) external pure override returns (uint256) {
        return 1;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage calldata) external payable override returns (bytes32) {
        return bytes32("ccipTestSend");
    }
}
