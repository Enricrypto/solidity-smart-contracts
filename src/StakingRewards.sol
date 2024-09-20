// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MockERC20.sol";

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    // The address of the contract owner (the one who deployed the contract).
    address public owner;

    // Variables to manage reward distribution.
    uint public duration; // The duration of the rewards period.
    uint public finishAt; // The timestamp when the rewards distribution ends.
    uint public updatedAt; // The last time the rewards were updated.
    uint public rewardRate; // The rate at which rewards are distributed (rewards per second).
    uint public rewardPerTokenStored; // Tracks the cumulative rewards per token.
    uint public totalSupply; // Total amount of staked tokens.

    // Mapping to track how much reward each user has earned and paid.
    mapping(address => uint) public rewardPerTokenPaid; // Tracks reward paid per token per user.
    mapping(address => uint) public rewards; // Tracks the total rewards for each user.
    mapping(address => uint) public balanceOf; // Stores the staked token balance for each user.

    // Modifier to restrict function access to only the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner"); // Ensures that only the owner can call the function.
        _;
    }

    // Modifier to update a user's reward before certain actions (stake, withdraw, get reward).
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken(); // Update the global reward per token.
        updatedAt = lastTimeRewardApplicable(); // Update the timestamp of the last reward update.

        // If an account is provided, update the user's reward details.
        if (_account != address(0)) {
            rewards[_account] = earned(_account); // Calculate the user's new earned rewards.
            rewardPerTokenPaid[_account] = rewardPerTokenStored; // Update the paid reward token value for the user.
        }

        _;
    }

    // Constructor function that initializes the staking and rewards tokens and sets the owner.
    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender; // Sets the owner to the address that deployed the contract.
        stakingToken = IERC20(_stakingToken); // Sets the staking token (the token users stake).
        rewardsToken = IERC20(_rewardsToken); // Sets the rewards token (the token users earn).
    }

    // Function to set the rewards duration. Can only be called by the owner.
    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "Reward duration not finished yet"); // Ensure that the current reward period has ended.
        duration = _duration; // Set the new rewards duration.
    }

    // Function to notify the contract of the reward amount available for distribution.
    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp > finishAt) {
            // If the reward period has ended, set a new reward rate.
            rewardRate = _amount / duration;
        } else {
            // If the reward period is still ongoing, calculate remaining rewards and adjust the rate.
            uint remainingRewards = rewardRate * (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount) / duration;
        }
        // Ensure the reward rate is greater than zero.
        require(rewardRate > 0, "Reward rate is less than or equal to zero");
        // Ensure the contract has enough reward tokens to distribute.
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "Not enough reward tokens"
        );
        finishAt = block.timestamp + duration; // Set the end time for the new reward period.
        updatedAt = block.timestamp; // Update the last reward update timestamp.
    }

    // Function to stake tokens. Users can stake a certain amount of staking tokens.
    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount must be greater than zero"); // Ensure the stake amount is positive.
        stakingToken.transferFrom(msg.sender, address(this), _amount); // Transfer the staked tokens to the contract.
        balanceOf[msg.sender] += _amount; // Update the user's staking balance.
        totalSupply += _amount; // Update the total supply of staked tokens.
    }

    // Function to withdraw staked tokens. Users can withdraw their staked amount.
    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount must be greater than zero"); // Ensure the withdrawal amount is positive.
        balanceOf[msg.sender] -= _amount; // Update the user's staking balance.
        totalSupply -= _amount; // Update the total supply of staked tokens.
        stakingToken.transfer(msg.sender, _amount); // Transfer the staked tokens back to the user.
    }

    // Function to get the last applicable time for rewards (either the current time or when rewards finish).
    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, finishAt); // Return the minimum of the current time and the finish time.
    }

    // Function to calculate the reward per token based on the total supply and reward rate.
    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored; // If no tokens are staked, return the stored reward per token.
        }
        // Calculate the new reward per token based on the reward rate and time passed since last update.
        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    // Function to calculate how much a specific user has earned in rewards.
    function earned(address _account) public view returns (uint) {
        // Calculate the user's earned rewards based on their staked balance and the updated reward per token.
        return
            (balanceOf[_account] *
                (rewardPerToken() - rewardPerTokenPaid[_account])) /
            1e18 +
            rewards[_account];
    }

    // Function to allow users to claim their rewards.
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender]; // Get the user's reward amount.
        if (reward > 0) {
            rewards[msg.sender] = 0; // Reset the user's reward balance.
            rewardsToken.transfer(msg.sender, reward); // Transfer the rewards to the user.
        }
    }

    // Internal function to return the minimum of two values.
    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y; // Return the smaller value.
    }
}
