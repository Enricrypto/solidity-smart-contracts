// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PriceOracle.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingMarket is PriceOracle {
    // declare both tokens as state variables
    IERC20 public lendingToken; // used for borrowing and repayment
    IERC20 public collateralToken; // used for collateral purposes
    PriceOracle public priceOracle;

    // User balances
    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public borrowedBalance;

    // The constructor must pass the necessary arguments to the PriceOracle constructor
    constructor(
        address _lendingToken,
        address _collateralToken,
        address _liquidityPool,
        address _token0,
        address _token1
    ) PriceOracle(_liquidityPool, _token0, _token1) {
        lendingToken = IERC20(_lendingToken);
        collateralToken = IERC20(_collateralToken);
    }

    // This function will transfer collateral from the user to the contract.
    function depositCollateral(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        collateralToken.transferFrom(msg.sender, address(this), _amount);
        collateralBalance[msg.sender] += _amount;
    }

    // This function allows users to borrow the lending token based on the collateral they have provided.
    function borrow(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Get the price of the collateral token in terms of the lending token
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the maximum borrowable amount based on the value of the collateral
        uint256 collateralValueInLendingToken = ((collateralBalance[
            msg.sender
        ] * collateralPrice) / 1e18);
        require(
            _amount <= collateralValueInLendingToken,
            "Borrow amount exceeds collateralized value"
        );

        // Update the user's borrowed balance
        borrowedBalance[msg.sender] += _amount;

        // Transfer the lending token to the user
        lendingToken.transfer(msg.sender, _amount);
    }

    // This function allows users to repay the amount they have borrowed.
    // Once the borrowed amount is repaid, they can withdraw their collateral.
    function repay(uint256 _amount) external {
        require(_amount > 0, "Amount to be repaid must be greater than 0");
        require(
            borrowedBalance[msg.sender] >= _amount,
            "Repay amount exceeds the borrowed amount"
        );

        // Update the user's borrowed balance
        borrowedBalance[msg.sender] -= _amount;

        // Transfer the lending token from the user to the contract
        lendingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawCollateral(uint256 _amount) external {
        require(_amount > 0, "Amount withdrawn must be greater than zero");

        // Get the price of the collateral token in terms of the lending token
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the value of the remaining collateral after withdrawal
        uint256 remainingCollateralValue = ((collateralBalance[msg.sender] -
            _amount) * collateralPrice) / 1e18;
        require(
            borrowedBalance[msg.sender] <= remainingCollateralValue,
            "Cannot withdraw more collateral"
        );

        // Update the user's collateral balance
        collateralBalance[msg.sender] -= _amount;

        // Transfer the collateral token back to the user
        collateralToken.transfer(msg.sender, _amount);
    }

    function getMaxBorrowableAmount(
        address _user
    ) external view returns (uint256) {
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );
        uint256 CollateralValueInLendingToken = (collateralBalance[_user] *
            collateralPrice) / 1e18;
        return CollateralValueInLendingToken;
    }

    function liquidate(address _user) external {
        // Retrieve the price of the collateral token relative to the lending token
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the current value of the user's collateral in terms of the lending token
        uint256 collateralValueInLendingToken = (collateralBalance[_user] *
            collateralPrice) / 1e18;

        // Checks if user's collateral is less than the user's borrowed amount.
        // If collateral value is less than borrowed amount, condition allows the function to proceed;
        // otherwise, it reverts.
        require(
            collateralValueInLendingToken < borrowedBalance[_user],
            "User's collateral is sufficient"
        );

        // Get the amount the liquidator needs to repay, which is the user's borrowed balance
        uint256 repaymentAmount = borrowedBalance[_user];

        // Reset the user's borrowed and collateral balances to zero to reflect the loan being repaid
        // and the collateral being transferred.
        borrowedBalance[_user] = 0;
        collateralBalance[_user] = 0;

        // Transfers the collateral to the liquidator
        collateralToken.transfer(msg.sender, collateralBalance[_user]);

        // Transfer the repayment amount from the liquidator to the contract
        lendingToken.transferFrom(msg.sender, address(this), repaymentAmount);
    }
}
