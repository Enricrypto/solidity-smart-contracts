// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DepositToken.sol";

// Vault contract inherits from the DepositToken contract.
contract Vault is DepositToken {
    // state variables. This is an instance of the DepositToken contract.
    DepositToken public depositToken;
    uint256 public totalAssets; // total number of DepositTokens that the Vault holds.
    uint256 public exchangeRate; // exchange rate

    // The constructor initializes the Vault token with a name ("Vault Token"),
    // symbol ("VAULT"), decimals (18), and an initial supply of 0.
    constructor(
        address _depositTokenAddress
    ) DepositToken("Vault Token", "VAULT", 18, 0) {
        // depositToken instance is initialized with address of the deployed DepositToken contract.
        depositToken = DepositToken(_depositTokenAddress);
    }

    function deposit(uint256 _amount) public returns (bool success) {
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer DepositTokens from the user to this contract
        bool transferSuccess = depositToken.transferFrom(
            msg.sender, // user's address (_from)
            address(this), // vault contract's address (_to)
            _amount
        );
        require(transferSuccess, "Transfer of DepositTokens failed");

        // * Update the total assets
        totalAssets += _amount;

        // * Calculate the number of shares to mint based on the current exchange rate
        uint256 sharesToMint = (totalSupply == 0 || totalAssets == 0)
            ? _amount
            : (totalSupply * _amount) / totalAssets;

        // Mint Vault tokens equivalent to the amount of DepositTokens deposited
        _mint(msg.sender, sharesToMint);

        // Update the exchange rate after amount of total assets change
        updateExchangeRate();

        return true;
    }

    // Update the total supply of Vault Tokens and the balance of the user.
    function _mint(
        address _to,
        uint256 _amount
    ) internal returns (bool success) {
        require(_to != address(0), "ERC20: mint to the zero address");

        totalSupply += _amount;

        balanceOf[_to] += _amount;

        // tokens have been minted (sent from the zero address).
        emit Transfer(address(0), _to, _amount);

        // Update the exchange rate after total supply change
        updateExchangeRate();

        return true;
    }

    // Vault tokens = shares
    function withdraw(uint256 _shares) public returns (bool success) {
        require(_shares > 0, "Amount must be greater than zero");
        require(
            balanceOf[msg.sender] >= _shares,
            "Insufficient balance to withdraw"
        );

        // * Calculate amount of DepositTokens you get when withdrawing a certain amount of shares from the Vault
        uint256 amountToTransfer = (totalAssets * _shares) / totalSupply;

        // Burn Vault tokens from the user
        _burn(msg.sender, _shares);

        // Transfer the equivalent amount of DepositTokens from this contract to the user
        bool transferSuccess = depositToken.transfer(
            msg.sender,
            amountToTransfer
        );
        require(transferSuccess, "Transfer of DepositTokens failed");

        // * Update the total assets
        totalAssets -= amountToTransfer;

        // Update the exchange rate after amount of total assets change
        updateExchangeRate();

        return true;
    }

    function _burn(
        address _from,
        uint256 _amount
    ) internal returns (bool success) {
        require(_from != address(0), "ERC20: burn from the zero address");

        // Decreases the user's balance by the _amount of Vault tokens.
        balanceOf[_from] -= _amount;

        // Decreases the total supply of Vault tokens.
        totalSupply -= _amount;

        // tokens have been burned (sent to the zero address).
        emit Transfer(_from, address(0), _amount);

        // Update the exchange rate after total supply change
        updateExchangeRate();

        return true;
    }

    function updateExchangeRate() internal {
        if (totalAssets == 0 || totalSupply == 0) {
            exchangeRate = 1; // Avoid division by zero, default to 1
        } else {
            // Using fixed-point arithmetic
            // By multiplying totalAssets by 1e18, you effectively scale it up to handle fractional values precisely.
            exchangeRate = (totalAssets * 1e18) / totalSupply;
        }
    }
}
