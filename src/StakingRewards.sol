// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MockERC20.sol";

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    // The address of the contract owner (the one who deployed the contract).
    address public owner;

    // Variables to manage reward distribution.
    uint256 public duration; // The duration of the rewards period.
    uint256 public finishAt; // The timestamp when the rewards distribution ends.
    uint256 public updatedAt; // The last time the rewards were updated.
    uint256 public rewardRate; // The rate at which rewards are distributed (rewards per second).
    uint256 public rewardPerTokenStored; // Tracks the cumulative rewards per token.
    uint256 public totalSupply; // Total amount of staked tokens.

    // Mapping to track how much reward each user has earned and paid.
    mapping(address => uint256) public rewardPerTokenPaid; // Tracks how much reward each user has already claimed.
    mapping(address => uint256) public rewards; // Tracks the total rewards for each user, but not yet claimed
    mapping(address => uint256) public balanceOf; // Stores the staked token balance for each user.

    // Constructor function that initializes the staking and rewards tokens and sets the owner.
    constructor(
        address _stakingToken,
        address _rewardsToken,
        uint256 _initialDuration
    ) {
        owner = msg.sender; // Sets the owner to the address that deployed the contract.
        stakingToken = IERC20(_stakingToken); // Sets the staking token (the token users stake).
        rewardsToken = IERC20(_rewardsToken); // Sets the rewards token (the token users earn).
        duration = _initialDuration;
        finishAt = block.timestamp; // Initialize finishAt to the current time
    }

    // Function to set the rewards duration. Can only be called by the owner.
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "Reward duration not finished yet"); // Ensure that the current reward period has ended.
        duration = _duration; // Set the new rewards duration.
    }

    // Function to notify the contract of the reward amount available for distribution. Can only be called by the owner.
    function notifyRewardAmount(
        uint256 _amount
    ) external onlyOwner updateReward(address(0)) {
        // address(0): the contract recalculates the necessary reward distribution metrics for everyone, not just a single user
        // at the beginning finishAt is at zero, no rewards will be available
        if (block.timestamp > finishAt) {
            // If the reward period has ended, set a new reward rate.
            rewardRate = _amount / duration;
        } else {
            // If the reward period is still ongoing, calculate remaining rewards and adjust the rate.
            uint256 remainingRewards = rewardRate *
                (finishAt - block.timestamp);
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

    // Function to calculate the reward per token based on the total supply and reward rate.
    // This function calculates and updates the rewards earned per token for the entire pool every time it is called.
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored; // If no tokens are staked, returns the last stored value of rewardPerTokenStored without any updates.
        }
        // Calculate the new reward per token based on the reward rate and time passed since last update.
        // The reason why rewardPerTokenStored is added to the newly calculated reward is that rewardPerTokenStored
        // represents the cumulative rewards per token up to the last time the rewards were updated.
        // When new rewards are calculated, they need to be added on top of the previously accumulated rewards.
        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    // Function to calculate how much a specific user has earned in rewards, but not yet claimed
    function earned(address _account) public view returns (uint256) {
        // Calculate the user's earned rewards based on their staked balance and the updated reward per token.
        return
            (balanceOf[_account] *
                (rewardPerToken() - rewardPerTokenPaid[_account])) /
            1e18 +
            rewards[_account]; // add all the rewards the user has not claimed yet.
    }

    // Function to stake tokens. Users can stake a certain amount of staking tokens.
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount must be greater than zero"); // Ensure the stake amount is positive.
        stakingToken.transferFrom(msg.sender, address(this), _amount); // Transfer the staked tokens to the contract.
        balanceOf[msg.sender] += _amount; // Update the user's staking balance.
        totalSupply += _amount; // Update the total supply of staked tokens.
    }

    // Function to withdraw staked tokens. Users can withdraw their staked amount.
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Amount must be greater than zero"); // Ensure the withdrawal amount is positive.
        balanceOf[msg.sender] -= _amount; // Update the user's staking balance.
        totalSupply -= _amount; // Update the total supply of staked tokens.
        stakingToken.transfer(msg.sender, _amount); // Transfer the staked tokens back to the user.
    }

    // Function to allow users to claim their rewards.
    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender]; // Get the user's reward amount.
        if (reward > 0) {
            // Reset the user's reward balance. Preventing reentrancy attacks and ensure that the reward is
            // only claimed once during the transaction.
            rewards[msg.sender] = 0; //
            rewardsToken.transfer(msg.sender, reward); // Transfer the rewards to the user.
        }
    }

    /**********************/
    /* Helper Functions */
    /**********************/

    // Function to get the last applicable time for rewards (either the current time or when rewards finish).
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(block.timestamp, finishAt); // Return the minimum of the current time and the finish time.
    }

    // Internal function to return the minimum of two values.
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y; // Return the smaller value.
    }

    /**********************/
    /* Modifier Functions */
    /**********************/

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
            // Whenever the user's rewards are updated, rewardPerTokenPaid[_account] is set equal to the
            // current rewardPerTokenStored. This "resets" the user’s rewards calculation point, ensuring that
            // the next time the user interacts with the contract (e.g., staking, withdrawing, or claiming rewards),
            // their rewards are calculated only from this update point forward.
            rewardPerTokenPaid[_account] = rewardPerTokenStored; // Update the paid reward token value for the user.
        }
        _;
    }
}
