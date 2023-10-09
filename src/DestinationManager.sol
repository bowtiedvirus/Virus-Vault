// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import {Vault} from "./Vault.sol";

error DestinationVaultManager__CallToVaultFailed();

contract DestinationVaultManager is CCIPReceiver {
    Vault public immutable si_vault;

    event SendSharesCallSuccessful();

    constructor(address router, address vaultAddress) CCIPReceiver(router) {
        si_vault = Vault(vaultAddress);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        // TODO: Need to verify the call came from an approved Sender Manager.

        (bool success,) = address(si_vault).call(message.data);
        if (!success) {
            revert DestinationVaultManager__CallToVaultFailed();
        }

        emit SendSharesCallSuccessful();
    }
}
