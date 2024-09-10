# Solidity Contracts 

This repository contains the Solidity smart contracts for the Gift Me platform, including `DepositToken`, `Vault`, and `Staking` contracts. These contracts are designed to facilitate token deposits, secure storage in vaults, and staking functionalities.

## Table of Contents
- [Introduction](#introduction)
- [Contracts Overview](#contracts-overview)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This repository contains the core Solidity contracts. The `DepositToken` contract handles token deposits, the `Vault` contract provides secure storage, and the `Staking` contract allows users to stake their tokens and earn rewards.

## Contracts Overview

### DepositToken
- **Purpose**: Handles the depositing of tokens by users.
- **Key Functions**:
  - `deposit(uint256 amount)`: Allows users to deposit a specified amount of tokens.
  - `withdraw(uint256 amount)`: Allows users to withdraw a specified amount of their deposited tokens.

### Vault
- **Purpose**: Provides secure storage for tokens.
- **Key Functions**:
  - `store(uint256 amount)`: Stores a specified amount of tokens in the vault.
  - `retrieve(uint256 amount)`: Retrieves a specified amount of tokens from the vault.

### Staking
- **Purpose**: Allows users to stake their tokens and earn rewards.
- **Key Functions**:
  - `stake(uint256 amount)`: Allows users to stake a specified amount of tokens.
  - `unstake(uint256 amount)`: Allows users to unstake a specified amount of tokens.
  - `claimRewards()`: Allows users to claim their staking rewards.

## Tech Stack

- **Solidity**: Programming language for writing smart contracts.
- **Foundry**: Framework for building, testing, and deploying smart contracts.

## Installation

1. **Clone the repository**:
    ```sh
    git clone https://github.com/yourusername/Solidity-contracts.git
    cd Solidity-contracts.git
    ```

2. **Install Foundry**:
    Follow the instructions to install Foundry from [Foundry's official documentation](https://getfoundry.sh/).

3. **Install dependencies**:
    ```sh
    forge install
    ```

## Configuration

Ensure you have the necessary configuration for your development environment. This includes having a local Ethereum node or access to a test network for deploying and testing the contracts.

## Usage

### Compile Contracts
Compile the smart contracts using Foundry:
```sh
forge build
```

### Deploy Contracts
Deploy the contracts to your desired network. You can use scripts or manual deployment methods provided by Foundry.

### Interact with Contracts
Use the deployed contract addresses and ABI definitions to interact with the contracts via your preferred method (e.g., web3.js, ethers.js, or directly through Foundry).

## Testing

### Run Tests
Run the provided tests using Foundry to ensure the contracts behave as expected:
```sh
forge test
```

### Test Coverage
Generate test coverage reports to identify untested code areas:
```sh
forge coverage
```

## Contributing

We welcome contributions to improve the functionality and security of these smart contracts. Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes and commit them (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Create a new Pull Request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

---

Thank you for contributing to my smart contracts repository! If you have any questions or need further assistance, feel free to open an issue or contact the project maintainers.


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
![Uploading image.png…]()

Build a Basic lending market.
1. It should accept one lending token and one Collateral token (How you specifically implement that is up to you. Just make sure you cant borrow the Collateral token and you cant use the lending token as collateral) ✅
2. It should use an Oracle that can be used to value the Collateral of a user and their loan value ✅
3. A user should be able to borrow up to an equal value to their Collateral (100$ Collateral = 100$ loan) ✅
4. Have a Liquidation function that anyone can call to repay the loan value of a user once the Collateral value of that user falls below their loan value. (If a user borrowed 100$ and Collateral is now 99$ the Liquidator would Transfer 100$ of the loan in and receive the Collateral of the user. Currently that function makes no economic sense but we will build upon it in the future) ✅

1) LTV ratio ✅  How can I calculate the LTV ratio based on market conditions and updated using the price Oracle? 
2) liquidation penalty ✅
3) fixed interest rate ✅ accruedInterest fucntion and BorrowInfo struct to calculate borrowed amount, interested accrued and time of interest

4) mint token lending market / claim interest payments , interest rate based on utilization