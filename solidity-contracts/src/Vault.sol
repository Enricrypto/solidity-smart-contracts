// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DepositToken.sol";

// Vault contract inherits from the DepositToken contract.
contract Vault is DepositToken {
    // state variable. This is an instance of the DepositToken contract.
    DepositToken public depositToken;

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
            msg.sender, // user's address
            address(this), // vault contract's address
            _amount
        );
        require(transferSuccess, "Transfer of DepositTokens failed");

        // Mint Vault tokens equivalent to the amount of DepositTokens deposited
        _mint(msg.sender, _amount);

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

        return true;
    }

    function withdraw(uint256 _amount) public returns (bool success) {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            balanceOf[msg.sender] >= _amount,
            "Insufficient balance to withdraw"
        );

        // Burn Vault tokens from the user
        _burn(msg.sender, _amount);

        // Transfer the equivalent amount of DepositTokens from this contract to the user
        bool transferSuccess = depositToken.transfer(msg.sender, _amount);
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

        // tokens have been burned (sent to the zero address).
        emit Transfer(_from, address(0), _amount);

        return true;
    }
}
