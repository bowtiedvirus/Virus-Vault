// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Vault} from "./Vault.sol";

contract SourceVaultManager is Ownable {
    Vault public immutable si_vault;

    address immutable i_router;
    address immutable i_link;

    mapping (uint64 => address) public approvedDestinationVaultManagers;

    event SendSharesMessageSent(bytes32 messageId);
    event SendSharesFeeEstimate(uint256 fee, address fee_token);

    constructor(address router, address link, address vaultAddress) Ownable() {
        i_router = router;
        i_link = link;
        si_vault = Vault(vaultAddress);
    }

    modifier onlyVault() {
        require(msg.sender == address(si_vault), "SourceMinter: Only the vault can call this function");
        _;
    }

    function setApprovedDestinationVaultManager(uint64 destinationChainSelector, address destinationVaultManager) external onlyOwner {
        approvedDestinationVaultManagers[destinationChainSelector] = destinationVaultManager;
    }

    receive() external payable {}

    function sendShares(
        address destinationAddress,
        uint256 amount,
        uint64 destinationChainSelector,
        address destinationVaultManager,
        address feeRefundAddress
    ) external payable onlyVault {
        require(approvedDestinationVaultManagers[destinationChainSelector] == destinationVaultManager, "SourceMinter: Destination vault manager not approved");

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationVaultManager),
            data: abi.encodeWithSignature("crossChainMint(address,uint256)", destinationAddress, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0) // Limiting to native token for simplicity for now
        });

        uint256 fee = IRouterClient(i_router).getFee(destinationChainSelector, message);

        if (msg.value < fee) {
            revert("SourceMinter: Not enough ETH to pay for fee");
        }

        bytes32 messageId;
        messageId = IRouterClient(i_router).ccipSend{value: fee}(destinationChainSelector, message);

        // Refund native token if overpaid for fee
        if (msg.value > fee) {
            payable(feeRefundAddress).transfer(msg.value - fee);
        }

        emit SendSharesMessageSent(messageId);
    }

    function estimateFeeForSendShares(
        address destinationAddress,
        uint256 amount,
        uint64 destinationChainSelector,
        address destinationVaultManager
    ) external onlyVault returns (uint256) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(destinationVaultManager),
            data: abi.encodeWithSignature("crossChainMint(address,uint256)", destinationAddress, amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(destinationChainSelector, message);

        emit SendSharesFeeEstimate(fee, address(0));
        return fee;
    }
}
