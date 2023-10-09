// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {MockERC20} from "@solmate/src/test/utils/mocks/MockERC20.sol";

import "../src/DestinationVaultManager.sol";
import {IYieldStrategy} from "../src/interfaces/IYieldStrategy.sol";
import {MockYieldStrategy, MockPool} from "./mocks/MockYieldStrategy.sol";
import {MockRouterClient} from "./mocks/MockRouterClient.sol";
import {MockCCIPReceiverRouter} from "./mocks/MockCCIPReceiverRouter.sol";
import {
    Vault,
    StrategyParams
} from "../src/Vault.sol";

contract DestinationVaultManagerTest is Test {
    DestinationVaultManager s_destVaultManager;
    MockCCIPReceiverRouter s_router;

    MockERC20 s_underlying;
    Vault s_vault;
    IYieldStrategy s_strategy;
    MockPool s_pool;

    address owner;
    address alice;
    address bob;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        s_underlying = new MockERC20("Mock Token", "TKN", 18);
        s_pool = new MockPool(s_underlying);

        vm.startPrank(owner);
        s_strategy = new MockYieldStrategy();
        s_vault = new Vault(s_underlying, "Mock Token Vault", "vwTKN", StrategyParams(s_strategy, address(s_pool)), address(0x0), payable(0x0));
        s_router = new MockCCIPReceiverRouter();
        s_destVaultManager = new DestinationVaultManager(address(s_router), address(s_vault));
        s_vault.setDestinationVaultManager(address(s_destVaultManager));
        s_destVaultManager.setApprovedSourceVaultManager(0, address(0x0));
        vm.stopPrank();
    }

    function testOnlyOwnerCanSetApprovedSourceVaultManager() public {
        vm.startPrank(owner);
        s_destVaultManager.setApprovedSourceVaultManager(0, address(0x1));
        vm.stopPrank();

        assertEq(s_destVaultManager.approvedSourceVaultManagers(0), address(0x1));
    }

    function testReceiveRevertsWithNonApprovedSender() public {
        vm.startPrank(address(s_router));

        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 0,
            sender: bytes("1"), // Only approved 0x0 for chain 0
            data: bytes(""),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.expectRevert();
        s_destVaultManager.ccipReceive(message);
    }
    
    function testReceiveRevertsWithNonApprovedChain() public {
        vm.startPrank(address(s_router));

        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 1, // Only approved 0x0 for chain 1.
            sender: bytes("0"),
            data: bytes(""),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.expectRevert();
        s_destVaultManager.ccipReceive(message);
    }

    function testReceiveWithNonVaultFunctionDataFails() public {
        vm.startPrank(owner);
        s_destVaultManager.setApprovedSourceVaultManager(69420, address(s_vault));
        vm.stopPrank();

        vm.startPrank(address(s_router));
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 69420,
            sender: abi.encode(address(s_vault)),
            data: abi.encodeWithSignature("otherFunction()"),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.expectRevert();
        s_destVaultManager.ccipReceive(message);
    }
    
    function testReceiveWithCrossChainMintDataMintsShares() public {
        vm.startPrank(owner);
        s_destVaultManager.setApprovedSourceVaultManager(69420, address(s_vault));
        vm.stopPrank();

        vm.startPrank(address(s_router));
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 69420,
            sender: abi.encode(address(s_vault)),
            data: abi.encodeWithSignature("crossChainMint(address,uint256)", address(alice), 100 ether),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        s_destVaultManager.ccipReceive(message);

        assertEq(s_vault.balanceOf(address(alice)), 100 ether);
    }
}
