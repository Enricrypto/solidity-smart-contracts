## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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

1. Write an ERC20. It should contain:

   - balance of users ✅
   - allowance of users ✅
   - approve function to set allowance of users ✅
   - Transfer function ✅
   - a function to pull Tokens from a user if the caller has enough of an allowance ✅
   - a mint function to set the balance of a user ✅

2. Create the ERC20 in Setup:

- test Transfer from one user to another ✅
- test for approving transfer ✅
- test for one user pull funds from another user ✅
- test minting for a user ✅
- in all Tests make sure that the balances and allowances match the expected value ✅

3. TESTS:

- Add a test for transferFrom that has 3 actors. Owner, Sender, Recipient.✅
  Sender should Transfer funds from owner to recipient. Assert correct allowances and balances for all 3 actors.✅
- Create a test that expects anyone but the owner to fail when minting new Tokens.✅

4. ERC20 Token: Vault

- Create another ERC20 token. Lets call it vault. It should interact with your previously created ERC20 which we can call depositToken. This vault doesnt have an owner nor an initial supply.✅
- It should have a deposit-function which takes in an amount of depositToken from the user and Transfers them into the vault contract. This should create a balance for the user and increase the supply.✅

- The vault contract should also have a withdraw-function. That function should burn vault Shares from the user. Decreasing supply and balance of the user. Then it should return the amount of depositToken equal to burned vault Shares.✅

5. Test that deposit and withdrawal are working.✅

6. Staking Contract

- Use the vault contract as your Basis for a staking contract. ✅
- When a user deposits assets they should receive an equal amount of vault Shares. ✅
- When withdrawing they should receive the same amount of assets as they burned Shares. ✅
- There should be a new function "Claim".✅
- This function should mint a third token (rewardsToken).✅
- Based on the amount of Shares a user controls and the time they staked for.✅
- (If a user owns 1 share and Claims 10s after depositing they should receive 10 rewardTokens) ✅
- (If a user owns 10 Shares and Claims 1s after depositing they should receive 10 rewardTokens) ✅
- (If a user withdraws and doesnt hold any Shares anymore they shouldnt receive any rewardTokens) ✅
- (If a user partially withdraws they should be able to Claim an adjusted amount based on the old deposit amount and time until withdrawal and than additional rewards based on their new balance after withdrawal) ✅
- Set a state variable for each user which tracks their deposit and claims ✅
- Users that have withdrawn but didnt Claim yet (they should receive rewardTokens for the time they have staked in the past) ✅
- Level would be to adjust how many rewards a user can Claim when they Transfer their vault Shares to a different user. (They should be able to Claim less/more after the Transfer) ✅
