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
Tasks: 

Build a Basic lending market.
1. It should accept one lending token and one Collateral token (How you specifically implement that is up to you. Just make sure you cant borrow the Collateral token and you cant use the lending token as collateral) ✅
2. It should use an Oracle that can be used to value the Collateral of a user and their loan value ✅
3. A user should be able to borrow up to an equal value to their Collateral (100$ Collateral = 100$ loan) ✅
4. Have a Liquidation function that anyone can call to repay the loan value of a user once the Collateral value of that user falls below their loan value. (If a user borrowed 100$ and Collateral is now 99$ the Liquidator would Transfer 100$ of the loan in and receive the Collateral of the user. Currently that function makes no economic sense but we will build upon it in the future) ✅