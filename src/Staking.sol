// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DepositToken.sol";
import "./Vault.sol";

// Staking contract inherits from the Vault contract.
contract Staking is Vault {
    // instance of the DepositToken contract
    DepositToken public rewardsToken;

    //a struct with shares and deposit time variables to calculate rewards accurately
    struct UserInfo {
        uint256 shares; // Amount of shares the user has
        uint256 lastClaimTime; // Timestamp of the last claim
        uint256 pendingRewards; // Rewards accrued but not yet claimed
    }

    mapping(address => UserInfo) public userInfo;

    constructor(
        // address of the deployed DepositToken contract for deposits.
        address _depositTokenAddress,
        // address of the deployed DepositToken contract for rewards.
        address _rewardsTokenAddress
    ) Vault(_depositTokenAddress) {
        // initializes the rewardsToken variable with the DepositToken contract
        // located at _rewardsTokenAddress
        rewardsToken = DepositToken(_rewardsTokenAddress);
    }

    // deposit token and mint new shares
    function depositVault(uint256 _amount) public returns (bool success) {
        require(_amount > 0, "Amount must be greater than zero");

        require(depositToken.balanceOf(msg.sender) >= _amount, "Insufficient funds");

        // variable "user" of type UserInfo (struct) is being set equal to the address calling the function
        UserInfo storage user = userInfo[msg.sender];

        // Calculate pending rewards before updating user data
        if (user.shares > 0) {
            uint256 pending = _calculatePendingRewards(user);
            user.pendingRewards += pending;
        }

        // Transfer DepositTokens from the user to this contract.
        // depositToken in Vault is inherited by Staking. So, Staking doesn't need to re-declare or re-initialize depositToken.
        // It automatically has access to depositToken as an inherited state variable.
        bool transferSuccess = depositToken.transferFrom(
            msg.sender, // user's address
            address(this), // contract's address
            _amount
        );
        require(transferSuccess, "Transfer of depositTokens failed");

        // Mint shares to the user equal to the deposited amount
        // _mint is called directly as it's an internal function on Vault contract and not a public function
        _mint(msg.sender, _amount);

        // Update user shares and deposit time
        user.shares += _amount;
        user.lastClaimTime = block.timestamp; // Reset claim time to now

        return true;
    }

    //withdraw shares from vault
    function withdrawVault(uint256 _amount) public returns (bool success) {
        require(_amount > 0, "Amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];
        require(user.shares >= _amount, "Insufficient shares to withdraw");

        // Calculate pending rewards before updating user data
        uint256 pending = _calculatePendingRewards(user);
        user.pendingRewards += pending;

        // Burn shares from the user
        _burn(msg.sender, _amount);

        // Transfer the equivalent amount of DepositTokens from this contract to the user
        bool transferSuccess = depositToken.transfer(msg.sender, _amount);
        require(transferSuccess, "Transfer of depositTokens failed");

        // Update user shares and deposit time
        user.shares -= _amount;
        user.lastClaimTime = block.timestamp; // Update claim time to now

        return true;
    }

    function claim() public returns (bool success) {
        UserInfo storage user = userInfo[msg.sender];

        // Calculate the pending rewards since the last claim
        uint256 pending = _calculatePendingRewards(user);
        user.pendingRewards += pending;

        // Ensure there are rewards to claim
        require(user.pendingRewards > 0, "No rewards to claim");

        // Calculate total rewards to claim and after that pending rewards should be set to 0
        uint256 rewardAmount = user.pendingRewards;
        user.pendingRewards = 0;

        // Mint reward tokens to the user using the internal mintRewards function
        _mintRewards(msg.sender, rewardAmount);

        // Reset the last claim time to the current time
        user.lastClaimTime = block.timestamp;

        return true;
    }

    // function allows a user (msg.sender) to transfer their vault shares (_amount)
    // to another address (_to)
    function transferShares(address _to, uint256 _amount) public returns (bool success) {
        UserInfo storage sender = userInfo[msg.sender];
        require(sender.shares >= _amount, "Insufficient shares to transfer");

        // Calculate pending rewards for sender
        uint256 senderPending = _calculatePendingRewards(sender);
        sender.pendingRewards += senderPending;

        // Transfer shares from sender to recipient
        UserInfo storage recipient = userInfo[_to];
        recipient.shares += _amount;

        // Adjust pending rewards for recipient
        uint256 recipientPending = _calculatePendingRewards(recipient);
        recipient.pendingRewards += recipientPending;

        // Update claim time to now
        sender.lastClaimTime = block.timestamp;
        recipient.lastClaimTime = block.timestamp;

        // Deduct shares from sender
        sender.shares -= _amount;

        return true;
    }

    // function to calculate the total pending rewards accrued by the user since their
    // last claim.
    function _calculatePendingRewards(UserInfo storage user) internal view returns (uint256) {
        // it's a view function as it doesn't modify the state, it only reads from it
        // Checks if the user has never claimed rewards.
        if (user.lastClaimTime == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - user.lastClaimTime;
        uint256 pending = (user.shares * stakingDuration) / 1e18;
        return pending;
    }

    // Internal function to mint rewards. This function is not directly callable by users,
    // ensuring that only the Staking contract (which acts on behalf of the admin) can mint the rewards.
    function _mintRewards(address _to, uint256 _amount) internal {
        rewardsToken.mint(_to, _amount);
    }
}
