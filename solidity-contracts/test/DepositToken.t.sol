// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DepositToken} from "../src/DepositToken.sol";

contract DepositTokenTest is Test {
    DepositToken public token;
    address public owner;
    address public sender;
    address public recipient;

    function setUp() public {
        owner = address(0x2);
        sender = address(this);
        recipient = address(0x1);

        //create a new instance of the token
        vm.prank(owner);
        token = new DepositToken("MyToken", "MTK", 18, 1000);

        // Mint initial tokens to the owner
        vm.prank(owner);
        token.mint(owner, 1000);

        // Transfer some tokens from owner to sender for testing transfer function
        vm.prank(owner);
        token.transfer(sender, 500);
    }

    // TEST TRANSFER
    function testTransfer() public {
        // Get initial balance of the sender
        uint256 initialOwnerBalance = token.balanceOf(sender);

        // Get initial balance of the recipient
        uint256 initialRecipientBalance = token.balanceOf(recipient);

        // Define transfer amount
        uint256 amount = 100;

        // Transfer tokens from sender to recipient
        token.transfer(recipient, amount);

        // Check if the sender's balance has decreased by the transfer amount
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
        // total supply is a public state variable, so it generates a getter function,
        // which is the reason why it's called with parenthesis
        uint256 initialTotalSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(recipient);
        uint256 mintedAmount = 100;

        // mint tokens
        vm.prank(owner);
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
        bool approvalSuccess = token.approve(recipient, allowanceAmount);

        assertTrue(approvalSuccess, "Approval was not succesful");

        assertEq(
            token.allowance(sender, recipient),
            allowanceAmount,
            "Allowance should match approved amount"
        );

        vm.prank(recipient);

        bool success = token.transferFrom(
            sender,
            recipient,
            allowanceAmount / 2
        );

        assertTrue(success, "Transfer was not succesful");

        assertEq(
            token.balanceOf(sender),
            initialBalanceOfSender - (allowanceAmount / 2),
            "Balance of sender should decrease by transferred amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalanceOfReceiver + (allowanceAmount / 2),
            "Balance of recipient should increase by transferred amount"
        );
        assertEq(
            token.allowance(sender, recipient),
            allowanceAmount / 2,
            "Token allowance should be 0"
        );

        vm.prank(recipient);

        success = token.transferFrom(sender, recipient, allowanceAmount / 2);

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
        assertEq(
            token.allowance(sender, recipient),
            0,
            "Token allowance should be 0"
        );
    }

    function testFailTransferFrom() public {
        vm.prank(recipient);
        token.transferFrom(sender, recipient, 100);
    }

    function testTransferFromMultiple() public {
        uint256 initialBalanceOfOwner = token.balanceOf(owner);
        uint256 initialBalanceOfRecipient = token.balanceOf(recipient);

        uint256 allowanceAmount = 1000;
        uint256 transferAmount = 100;

        // Approve allowance from owner to sender
        vm.prank(owner);
        bool approveAllowance = token.approve(sender, allowanceAmount);
        assertTrue(approveAllowance, "Approval was not successful");

        // Check allowance after approval
        uint256 allowance = token.allowance(owner, sender);
        assertEq(
            allowance,
            allowanceAmount,
            "Allowance should be set correctly"
        );

        // Transfer tokens from owner to recipient
        vm.prank(sender); // Ensure the transferFrom call is made by the sender
        bool approveTransfer = token.transferFrom(
            owner,
            recipient,
            transferAmount
        );
        assertTrue(
            approveTransfer,
            "Transfer from owner to sender was not successful"
        );

        // Check balances after transfer from owner to recipient
        assertEq(
            token.balanceOf(owner),
            initialBalanceOfOwner - transferAmount,
            "Balance of owner should decrease by transferred amount"
        );
        assertEq(
            token.balanceOf(recipient),
            initialBalanceOfRecipient + transferAmount,
            "Balance of recipient should increase by transferred amount"
        );

        // Check final allowance
        assertEq(
            token.allowance(owner, sender),
            allowanceAmount - transferAmount, // Only the transferFrom affects the allowance
            "Allowance of owner to sender should decrease by transfer amount"
        );
    }

    function testFailMinting() public {
        // Ensure the owner has enough tokens for testing
        uint256 initialBalanceOfOwner = token.balanceOf(owner);
        uint256 mintAmount = 100;

        // Non-owner address trying to mint tokens
        address nonOwner = address(0x3);

        vm.prank(nonOwner);

        // Attempt minting by non-owner
        bool mintByNonOwner = token.mint(nonOwner, mintAmount);
        assertFalse(mintByNonOwner, "Non-owner was able to mint tokens");

        // Check if the balance of non-owner remains unchanged
        assertEq(
            token.balanceOf(nonOwner),
            0,
            "Non-owner balance should remain unchanged"
        );

        // Ensure the owner can mint tokens successfully
        vm.prank(owner);
        bool mintByOwner = token.mint(owner, mintAmount);
        assertTrue(mintByOwner, "Owner failed to mint tokens");

        // Check if the balance of the owner has increased by mintAmount
        assertEq(
            token.balanceOf(owner),
            initialBalanceOfOwner + mintAmount,
            "Owner balance should increase by mint amount"
        );
    }
}
