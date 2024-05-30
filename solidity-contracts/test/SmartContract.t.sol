// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Token} from "../src/SmartContract.sol";

contract ERC20TokenTest is Test {
    ERC20Token public token;
    address public sender;
    address public recipient;

    function setUp() public {
        sender = address(this);
        recipient = address(0x1);

        token = new ERC20Token("MyToken", "MTK", 18, 1000);
    }

    // TEST TRANSFER
    function testTransfer() public {
        // Get initial balance of the owner
        uint256 initialOwnerBalance = token.balanceOf(sender);

        // Get initial balance of the recipient
        uint256 initialRecipientBalance = token.balanceOf(recipient);

        // Define transfer amount
        uint256 amount = 100;

        // Transfer tokens from owner to recipient
        token.transfer(recipient, amount);

        // Check if the owner's balance has decreased by the transfer amount
        assertEq(
            token.balanceOf(sender),
            initialOwnerBalance - amount,
            "Owner balance incorrect after transfer"
        );

        // Check if the recipient's balance has increased by the transfer amount
        assertEq(
            token.balanceOf(recipient),
            initialRecipientBalance + amount,
            "Recipient balance incorrect after transfer"
        );
    }

    // TEST APPROVE
    function testApprove() public {
        uint256 amount = 100;

        bool success = token.approve(recipient, amount);

        // confirm approval was succesful
        assertTrue(success, "Approval was not succesful");

        // confirm allowance is approved
        assertEq(
            token.allowance(sender, recipient),
            amount,
            "Allowance set up to 100"
        );
    }

    // TEST MINTING
    function testMinting() public {
        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(recipient);
        uint256 mintedAmount = 100;

        // mint tokens
        bool success = token.mint(recipient, mintedAmount);

        //verify minting process was succesful
        assertTrue(success, "Minting process was not succesful");

        assertEq(
            token.totalSupply(),
            initialTotalSupply + mintedAmount,
            "Total supply should increase by minted amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalance + mintedAmount,
            "Balance should increase by minted amount"
        );
    }

    // TEST TRANSFER FROM
    function testTransferFrom() public {
        uint256 initialBalanceOfSender = token.balanceOf(sender);
        uint256 initialBalanceOfReceiver = token.balanceOf(recipient);
        uint256 allowanceAmount = 100;

        // approve allowance for transfer
        bool approvalSuccess = token.approve(sender, allowanceAmount);

        assertTrue(approvalSuccess, "Approval was not succesful");

        assertEq(
            // address(this): This expression converts the current contract instance (this)
            // into an Ethereum address.
            token.allowance(sender, address(this)),
            allowanceAmount,
            "Allowance should match approved amount"
        );

        bool success = token.transferFrom(sender, recipient, allowanceAmount);

        assertTrue(success, "Transfer was not succesful");

        assertEq(
            token.balanceOf(sender),
            initialBalanceOfSender - allowanceAmount,
            "Balance of sender should decrease by transferred amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalanceOfReceiver + allowanceAmount,
            "Balance of recipient should increase by transferred amount"
        );
    }
}
