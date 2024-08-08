// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DepositToken.sol";
import "../src/Staking.sol";

contract StakingTest is Test {
    DepositToken depositToken;
    DepositToken rewardsToken;
    Staking staking;

    address public user;
    address public owner;

    event Caller(address indexed owner);

    function setUp() public {
        // Set the owner address to this contract's address
        owner = address(this);

        depositToken = new DepositToken("MyToken", "MTK", 18, 1000);
        rewardsToken = new DepositToken("MyrewardsToken", "MTK", 18, 1000);

        // Deploy the Staking contract with the correct owner address
        staking = new Staking(address(depositToken), address(rewardsToken));

        // set user's address
        user = address(0x1);

        // Change admin of rewardsToken to the staking contract
        // vm.prank(owner);
        emit Caller(owner);
        rewardsToken.changeAdmin(address(staking));

        // The depositToken mints 1000 tokens to user
        depositToken.mint(user, 1000);

        // The depositToken contract approves staking to spend up to 1000 tokens on behalf of user.
        vm.prank(user);
        depositToken.approve(address(staking), 500);
    }

    function testDeposit() public {
        vm.prank(user);
        // user deposits 100 tokens into the staking contract
        bool success = staking.depositVault(100);
        assertTrue(success);
        // destructuring: the variables inside the parenthesis should be assigned values from
        // the return values of staking.userInfo(user) in the order they are declared.
        (
            uint256 shares,
            uint256 lastClaimTime,
            uint256 pendingRewards
        ) = staking.userInfo(user);
        assertEq(shares, 100);
        assertEq(lastClaimTime, block.timestamp);
        assertEq(pendingRewards, 0);
    }

    function testWithdraw() public {
        vm.prank(user);
        staking.depositVault(100);

        // Time is fast forwarded by 1 day; used to simulate the passage of time in the test environment.
        vm.warp(block.timestamp + 1 days);

        vm.prank(user);
        bool success = staking.withdrawVault(100);
        assertTrue(success);

        (uint256 shares, , uint256 pendingRewards) = staking.userInfo(user);
        assertEq(shares, 0);
        assertEq(pendingRewards, 100 * 1 days);
    }

    function testClaim() public {
        vm.prank(user);
        // deposit 100 tokens in vault
        staking.depositVault(100);

        // Time is fast forwarded by 1 day; used to simulate the passage of time in the test environment.
        vm.warp(block.timestamp + 1 days);

        // claim
        vm.prank(user);
        bool success = staking.claim();
        assertTrue(success);

        uint256 rewardBalance = rewardsToken.balanceOf(user);
        assertEq(rewardBalance, 100 * 1 days);

        (, uint256 lastClaimTime, uint256 pendingRewards) = staking.userInfo(
            user
        );
        assertEq(lastClaimTime, block.timestamp);
        assertEq(pendingRewards, 0);
    }

    function testTransferShares() public {
        address recipient = address(2);

        vm.prank(user);
        staking.depositVault(100);

        vm.prank(user);
        bool success = staking.transferShares(recipient, 50);
        assertTrue(success);

        (uint256 senderShares, , ) = staking.userInfo(user);
        assertEq(senderShares, 50);

        (uint256 recipientShares, , ) = staking.userInfo(recipient);
        assertEq(recipientShares, 50);
    }
}
