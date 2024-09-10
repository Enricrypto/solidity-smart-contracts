// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import {Test} from "lib/forge-std/src/Test.sol";
// import "../src/DepositToken.sol";
// import "../src/Staking.sol";

// contract StakingTest is Test {
//     DepositToken depositToken;
//     DepositToken rewardsToken;
//     Staking staking;

//     address public user;
//     address public owner;

//     event Caller(address indexed owner);

//     function setUp() public {
//         // Set the owner address to this contract's address
//         owner = address(this);

//         // Deploy DepositToken and RewardsToken contracts
//         depositToken = new DepositToken("MyToken", "MTK", 18, 1000);
//         rewardsToken = new DepositToken("MyRewardsToken", "MRK", 18, 1000);

//         // Deploy Staking contract with initial setup
//         staking = new Staking(address(depositToken), address(rewardsToken));

//         // Set the user's address
//         user = address(0x1);

//         // Change admin of rewardsToken to the staking contract
//         emit Caller(owner);
//         rewardsToken.changeAdmin(address(staking));

//         // Mint 1000 DepositTokens to the user
//         depositToken.mint(user, 1000);

//         // Approve the staking contract to spend up to 500 DepositTokens on behalf of the user
//         vm.prank(user);
//         depositToken.approve(address(staking), 500);
//     }

//     function testDeposit() public {
//         vm.prank(user);
//         // User deposits 100 tokens into the staking contract
//         bool success = staking.depositVault(100);
//         assertTrue(success);

//         // Retrieve user's information
//         (
//             uint256 shares,
//             uint256 lastClaimTime,
//             uint256 pendingRewards
//         ) = staking.userInfo(user);

//         // Check that the shares, lastClaimTime, and pendingRewards are as expected
//         assertEq(shares, 100);
//         assertEq(lastClaimTime, block.timestamp);
//         assertEq(pendingRewards, 0);
//     }

//     function testWithdraw() public {
//         vm.prank(user);
//         staking.depositVault(100);

//         // Time is fast-forwarded by 1 day
//         vm.warp(block.timestamp + 1 days);

//         vm.prank(user);
//         bool success = staking.withdrawVault(100);
//         assertTrue(success);

//         // Retrieve user's information
//         (uint256 shares, , uint256 pendingRewards) = staking.userInfo(user);

//         // Expecting 100 tokens as rewards for 1 day
//         uint256 expectedRewards = 100;
//         assertEq(shares, 0);
//         assertEq(pendingRewards, expectedRewards);
//     }

//     function testClaim() public {
//         vm.prank(user);
//         // Deposit 100 tokens in the vault
//         staking.depositVault(100);

//         // Time is fast-forwarded by 1 day
//         vm.warp(block.timestamp + 1 days);

//         // User claims their rewards
//         vm.prank(user);
//         bool success = staking.claim();
//         assertTrue(success);

//         // Check that the reward balance of the user is as expected
//         uint256 rewardBalance = rewardsToken.balanceOf(user);
//         assertEq(rewardBalance, 100);

//         // Retrieve user's information
//         (, uint256 lastClaimTime, uint256 pendingRewards) = staking.userInfo(
//             user
//         );

//         // Check that the lastClaimTime and pendingRewards are as expected
//         assertEq(lastClaimTime, block.timestamp);
//         assertEq(pendingRewards, 0);
//     }

//     function testTransferShares() public {
//         address recipient = address(0x2);

//         vm.prank(user);
//         // User deposits 100 tokens in the vault
//         staking.depositVault(100);

//         // User transfers 50 shares to the recipient
//         vm.prank(user);
//         bool success = staking.transferShares(recipient, 50);
//         assertTrue(success);

//         // Retrieve information for both the sender and the recipient
//         (uint256 senderShares, , ) = staking.userInfo(user);
//         (uint256 recipientShares, , ) = staking.userInfo(recipient);

//         // Check that the sender's and recipient's shares are as expected
//         assertEq(senderShares, 50);
//         assertEq(recipientShares, 50);
//     }
// }
