// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Vault.sol";
import "../src/MakerDAOYieldStrategy.sol";

contract GoerliDeployVault is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MakerDAOYieldStrategy strategy = new MakerDAOYieldStrategy();
        Vault vault =
        new Vault(ERC20(0x5C221E77624690fff6dd741493D735a17716c26B), "Mock Token Vault", "vwTKN", StrategyParams(strategy, address(0xF7F0de3744C82825D77EdA8ce78f07A916fB6bE7)));

        vm.stopBroadcast();

        return address(vault);
    }
}
