// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {OwnableERC4626} from "./OwnableERC4626.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error BadAddress();
error BadCrossChainShareAmount(uint256 amount);

contract Vault is Ownable {
    OwnableERC4626 immutable vault;
    
    constructor(
        ERC20 asset, 
        string memory name,
        string memory symbol
        ) Ownable() {
        vault = new OwnableERC4626(asset, name, symbol);
    }

    function deposit(uint256 assets, address receiver) public onlyOwner returns (uint256) {
        return vault.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public onlyOwner returns (uint256) {
        return vault.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public onlyOwner returns (uint256) {
        return vault.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public onlyOwner returns (uint256) {
        return vault.redeem(shares, receiver, owner);
    }
    
}



// TAKEN FROM Cross Chain idea draft
    // function crossChainSendUnderlying(uint256 amount) public onlyOwner {
    //     vault.transferUnderlyingToOwner(amount);
        
    //     // Create token transfer message for CCIP
    //     // Transfer tokens to CCIP Receiver
    // }

    // function crossChainSendShares(uint256 amount, string memory destinationChain, address destinationAddress) public {
    //     uint256 vaultShareBalance = vault.balanceOf(msg.sender);

    //     if (0 == amount || amount > vaultShareBalance) {
    //         revert BadCrossChainShareAmount(amount);
    //     }

    //     // Construct message
    //     // Send message
    //     // Burn shares of token for user
    // }

    // function receiveUnderlying(uint256 amount) public onlyOwner {
    //     SafeERC20.safeTransferFrom(_asset, address(this), vault, assets);
    // }
    
    // function crossChainReceiveShares(ccip details) ensureSentByCCIP public {
    //     // require sender payload was sent from approved sender and chain (ccip details)
    //     // Mint shares for user at given destinationAddress
    // }
