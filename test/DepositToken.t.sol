// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {DepositToken} from "../src/DepositToken.sol";

contract DepositTokenTest is Test {
    DepositToken public token;
    address public admin; // contract owner
    address public sender; // owner of the tokens
    address public spender; // spender (third-party) address
    address public recipient; // recipient of the tokens

    function setUp() public {
        admin = address(this);
        sender = address(0x1);
        spender = address(0x2);
        recipient = address(0x3);

        //create a new instance of the token
        vm.prank(admin);
        token = new DepositToken("MyToken", "MTK", 18, 1000);

        // Transfer some tokens from admin to sender for testing transfer function
        vm.prank(admin);
        token.transfer(sender, 500);
    }

    // TEST TRANSFER
    function testTransfer() public {
        // Get initial balance of the sender
        uint256 initialSenderBalance = token.balanceOf(sender);

        // Get initial balance of the recipient
        uint256 initialRecipientBalance = token.balanceOf(recipient);

        // Define transfer amount
        uint256 amount = 100;

        // Transfer tokens from sender to recipient
        vm.prank(sender);
        token.transfer(recipient, amount);

        // Check if the sender's balance has decreased by the transfer amount
        assertEq(token.balanceOf(sender), initialSenderBalance - amount, "Sender balance incorrect after transfer");

        // Check if the recipient's balance has increased by the transfer amount
        assertEq(
            token.balanceOf(recipient), initialRecipientBalance + amount, "Recipient balance incorrect after transfer"
        );
    }

    // TEST APPROVE
    function testApprove() public {
        uint256 amount = 100;

        vm.prank(sender);
        bool success = token.approve(spender, amount);

        // confirm approval was succesful
        assertTrue(success, "Approval was not succesful");

        // confirm allowance is approved
        assertEq(token.allowance(sender, spender), amount, "Allowance set up to 100");
    }

    // TEST MINTING
    function testMint() public {
        // total supply is a public state variable, so it generates a getter function,
        // which is the reason why it's called with parenthesis
        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(recipient);
        uint256 mintedAmount = 100;

        // mint tokens
        vm.prank(admin);
        bool success = token.mint(recipient, mintedAmount);

        //verify minting process was succesful
        assertTrue(success, "Minting process was not succesful");

        assertEq(
            token.totalSupply(), initialTotalSupply + mintedAmount, "Total supply should increase by minted amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalance + mintedAmount,
            "Balance of recipient should increase by minted amount"
        );
    }

    // TEST TRANSFER FROM
    function testTransferFrom() public {
        uint256 initialBalanceOfSender = token.balanceOf(sender);
        uint256 initialBalanceOfRecipient = token.balanceOf(recipient);
        uint256 allowanceAmount = 100;

        // Approve allowance for recipient to spend sender's tokens
        vm.prank(sender);
        bool approvalSuccess = token.approve(recipient, allowanceAmount);

        assertTrue(approvalSuccess, "Approval was not successful");

        assertEq(token.allowance(sender, recipient), allowanceAmount, "Allowance should match approved amount");

        // Perform transferFrom by recipient who's acting like the spender on this case (transferring to itself)
        vm.prank(recipient);
        bool success = token.transferFrom(sender, recipient, allowanceAmount / 2);
        assertTrue(success, "Transfer was not successful");

        assertEq(
            token.balanceOf(sender),
            initialBalanceOfSender - (allowanceAmount / 2),
            "Balance of sender should decrease by transferred amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalanceOfRecipient + (allowanceAmount / 2),
            "Balance of recipient should increase by transferred amount"
        );
        assertEq(
            token.allowance(sender, recipient),
            allowanceAmount / 2,
            "Allowance should be reduced by the transferred amount"
        );

        // Perform another transferFrom by recipient (acting as spender)
        vm.prank(recipient);
        success = token.transferFrom(sender, recipient, allowanceAmount / 2);
        assertTrue(success, "Transfer was not successful");

        assertEq(
            token.balanceOf(sender),
            initialBalanceOfSender - allowanceAmount,
            "Balance of sender should decrease by transferred amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalanceOfRecipient + allowanceAmount,
            "Balance of recipient should increase by transferred amount"
        );
        assertEq(token.allowance(sender, recipient), 0, "Token allowance should be 0 after full transfer");
    }

    // test checking that recipient is trying to transfer tokens from sender without been given an allowance
    function testFailTransferFrom() public {
        vm.prank(recipient);
        token.transferFrom(sender, recipient, 100);
    }

    function testTransferFromMultiple() public {
        uint256 initialBalanceOfSender = token.balanceOf(sender);
        uint256 initialBalanceOfRecipient = token.balanceOf(recipient);

        uint256 allowanceAmount = 1000;
        uint256 transferAmount = 100;

        // Approve allowance from sender to recipient
        vm.prank(sender);
        bool approveAllowance = token.approve(spender, allowanceAmount);
        assertTrue(approveAllowance, "Approval was not successful");

        // Check allowance after approval
        uint256 allowance = token.allowance(sender, spender);
        assertEq(allowance, allowanceAmount, "Allowance should be set correctly");

        // Transfer tokens from sender to recipient
        vm.prank(spender); // Ensure the transferFrom call is made by the spender, sending to recipient (third-party)
        bool approveTransfer = token.transferFrom(sender, recipient, transferAmount);
        assertTrue(approveTransfer, "Transfer from admin to sender was not successful");

        // Check balances after transfer from admin to recipient
        assertEq(
            token.balanceOf(sender),
            initialBalanceOfSender - transferAmount,
            "Balance of sender should decrease by transferred amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalanceOfRecipient + transferAmount,
            "Balance of recipient should increase by transferred amount"
        );

        // Check final allowance
        assertEq(
            token.allowance(sender, spender),
            allowanceAmount - transferAmount, // Only the transferFrom affects the allowance
            "Allowance of sender to recipient should decrease by transfer amount"
        );
    }

    function testFailMint() public {
        // Ensure the admin has enough tokens for testing
        uint256 initialBalanceOfSender = token.balanceOf(admin);
        uint256 mintAmount = 100;

        // Non-admin address trying to mint tokens (could be sender, recipient, spender)
        address nonadmin = address(0x4);

        vm.prank(nonadmin);

        // Attempt minting by non-admin
        bool mintByNonadmin = token.mint(nonadmin, mintAmount);
        assertFalse(mintByNonadmin, "Non-admin was able to mint tokens");

        // Check if the balance of non-admin remains unchanged
        assertEq(token.balanceOf(nonadmin), 0, "Non-admin balance should remain unchanged");

        // Ensure the admin can mint tokens successfully
        vm.prank(admin);
        bool mintByAdmin = token.mint(sender, mintAmount); // admin mint tokens to sender
        assertTrue(mintByAdmin, "admin failed to mint tokens");

        // Check if the balance of the sender has increased by mintAmount
        assertEq(
            token.balanceOf(sender), initialBalanceOfSender + mintAmount, "admin balance should increase by mint amount"
        );
    }
}
