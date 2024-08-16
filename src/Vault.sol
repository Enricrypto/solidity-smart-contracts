// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DepositToken.sol";

// Vault contract inherits from the DepositToken contract
contract Vault is DepositToken {
    // state variable. This is an instance of the DepositToken contract that doesn't alter the DepositToken contract
    DepositToken public depositToken;

    // The constructor initializes the Vault token with a name ("Vault Token"),
    // symbol ("VAULT"), decimals (18), and an initial supply of 0
    // Calls the constructor of the DepositToken contract with specific parameters for the Vault token.
    // This sets the name, symbol, decimals, and initial supply for the Vault token
    constructor(
        address _depositTokenAddress
    ) DepositToken("Vault Token", "VAULT", 18, 0) {
        // depositToken instance is initialized with address of the deployed DepositToken contract.
        // This allows the Vault to interact with the DepositToken contract
        depositToken = DepositToken(_depositTokenAddress);
    }

    // function to deposit tokens and receive vault tokens (shares) in exchange
    function deposit(uint256 _amount) public returns (bool success) {
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer DepositTokens from the user to this contract
        bool transferSuccess = depositToken.transferFrom(
            msg.sender, // user's address (_from)
            address(this), // vault contract's address (_to)
            _amount
        );
        require(transferSuccess, "Transfer of DepositTokens failed");

        // Calculate the number of shares to mint
        // totalSupply represents the total amount of shares minted by the vault
        // totalAssets() is the total balance of tokens currently held in the vault
        uint256 sharesToMint = (totalSupply == 0 || totalAssets() == 0) // in case the vault is empty
            ? _amount
            : (totalSupply * _amount) / totalAssets(); // maintain proportion of shares, i.e: (1000 shares * 100 tokens) / 1000 tokens = 100 shares

        // Mint Vault tokens equivalent to the amount of DepositTokens deposited
        _mint(msg.sender, sharesToMint);

        return true;
    }

    // Update the total supply of Vault Tokens and the balance of the user.
    function _mint(
        address _to,
        uint256 _amount
    ) internal returns (bool success) {
        require(_to != address(0), "ERC20: mint to the zero address");

        // 1. Update the total supply
        totalSupply += _amount;

        // 2. Update the balance of the recipient
        balanceOf[_to] += _amount;

        // 3. Emit the Transfer event to signal that tokens have been minted (sent from the zero address).
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    // function to withdraw vault tokens (shares) and receive deposit tokens in exchange
    function withdraw(uint256 _shares) public returns (bool success) {
        require(_shares > 0, "Amount must be greater than zero");

        // check that user calling the function has enough vault tokens (shares) to withdraw
        require(
            balanceOf[msg.sender] >= _shares,
            "Insufficient balance to withdraw"
        );

        // * Calculate amount of DepositTokens you get when withdrawing a certain amount of shares from the Vault
        uint256 amountToTransfer = (totalAssets() * _shares) / totalSupply;

        // Burn Vault tokens from the user
        _burn(msg.sender, _shares);

        // Transfer the equivalent amount of DepositTokens from the contract (vault) to the user
        bool transferSuccess = depositToken.transfer(
            msg.sender,
            amountToTransfer
        );
        require(transferSuccess, "Transfer of DepositTokens failed");

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

        // tokens have been burnt (sent to the zero address).
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    // DYNAMIC Function to calculate the total value of assets managed by the vault.
    // Returns the sum of all the assets (tokens) that are deposited in the vault.
    // This value could be in terms of the underlying tokens that the vault holds or manages.
    function totalAssets() public view returns (uint256) {
        // balance of the Vault ===> address(this)
        return depositToken.balanceOf(address(this));
    }
}
