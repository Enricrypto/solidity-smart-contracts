// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {Vault} from "../src/Vault.sol";
import {DepositToken} from "../src/DepositToken.sol";

contract VaultTest is Test {
    // state variables
    Vault public vault;
    DepositToken public depositToken;
    address public sender;

    function setUp() public {
        sender = address(this);

        depositToken = new DepositToken("MyToken", "MTK", 18, 1000);

        depositToken.mint(sender, 500);

        vault = new Vault(address(depositToken));
        depositToken.approve(address(vault), type(uint256).max); // Approving a large amount for testing
    }

    function testDeposit() public {
        uint256 initialVaultBalance = depositToken.balanceOf(address(vault));
        uint256 initialSenderBalance = depositToken.balanceOf(sender);
        uint256 depositAmount = 100;

        // Approve the Vault contract to spend tokens on behalf of the sender
        depositToken.approve(address(vault), depositAmount);

        vault.deposit(depositAmount);

        assertEq(
            // Retrieves the current balance of the Vault contract in terms of the DepositToken.
            depositToken.balanceOf(address(vault)),
            initialVaultBalance + depositAmount,
            "Vault balance incorrect after deposit"
        );

        assertEq(
            depositToken.balanceOf(sender),
            initialSenderBalance - depositAmount,
            "Sender balance incorrect after deposit"
        );

        assertEq(
            // Retrieves the balance of the sender within the Vault contract.
            vault.balanceOf(sender),
            depositAmount,
            "Vault balance of sender incorrect after deposit"
        );
    }

    function testWithdraw() public {
        uint256 initialVaultBalance = depositToken.balanceOf(address(vault));
        uint256 initialSenderBalance = depositToken.balanceOf(sender);

        uint256 withdrawAmount = 50;

        // Approve the Vault contract to spend tokens on behalf of the sender
        depositToken.approve(address(vault), withdrawAmount);

        // It simulates a user depositing tokens into the Vault before withdrawal.
        vault.deposit(withdrawAmount);

        // It simulates a user withdrawing tokens from the Vault.
        vault.withdraw(withdrawAmount);

        assertEq(
            depositToken.balanceOf(address(vault)),
            initialVaultBalance,
            "Vault balance incorrect after withdrawal"
        );

        assertEq(
            depositToken.balanceOf(sender),
            initialSenderBalance,
            "Sender balance incorrect after withdrawal"
        );

        // It ensures that the tokens were successfully withdrawn from
        // the Vault and that the sender's Vault balance is now empty.
        assertEq(
            vault.balanceOf(sender),
            0,
            "Vault balanceOf sender incorrect after withdrawal"
        );
    }
}
