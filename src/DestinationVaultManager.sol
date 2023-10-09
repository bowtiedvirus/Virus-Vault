// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


import {Vault} from "./Vault.sol";

error DestinationVaultManager__CallToVaultFailed();

contract DestinationVaultManager is CCIPReceiver, Ownable {
    Vault public immutable si_vault;

    mapping (uint64 => address) public approvedSourceVaultManagers;


    event SendSharesCallSuccessful();

    constructor(address router, address vaultAddress) Ownable() CCIPReceiver(router) {
        si_vault = Vault(vaultAddress);
    }

    function setApprovedSourceVaultManager(uint64 sourceChainSelector, address sourceVaultManager) external onlyOwner {
        approvedSourceVaultManagers[sourceChainSelector] = sourceVaultManager;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        address sender = abi.decode(message.sender, (address));
        require(approvedSourceVaultManagers[message.sourceChainSelector] == sender, "DestinationVaultManager: Source vault manager address not approved");

        (bool success,) = address(si_vault).call(message.data);
        if (!success) {
            revert DestinationVaultManager__CallToVaultFailed();
        }

        emit SendSharesCallSuccessful();
    }
}
