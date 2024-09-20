// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceOracle.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingMarket {
    // declare both tokens as state variables
    IERC20 public lendingToken; // used for borrowing and repayment
    IERC20 public collateralToken; // used for collateral purposes
    PriceOracle public priceOracle;

    // address of the contract admin
    address public admin;

    // Loan-to-Value Ratio (LTV) expressed in percentage with 18 decimal precision (e.g., 50% is 50e18)
    uint256 public ltvRatio;

    // state variable to define the penalty rate.
    // A percentage of the collateral that will be taken as a penalty during liquidation
    uint256 public liquidationPenalty; // e.g., 10% penalty is 0.1 * 1e18 = 100000000000000000

    // Fixed interest rate, per year (e.g., 5% = 0.05 * 1e18)
    uint256 public interestRate;

    // Struct to track when each user last borrowed to accurately calculate the accrued interest.
    struct BorrowInfo {
        uint256 borrowedAmount;
        uint256 interestAccrued;
        uint256 lastBorrowTimestamp;
    }

    // User balances
    mapping(address => uint256) public collateralBalance;
    mapping(address => BorrowInfo) public borrowInfo;

    // event of who calls the function
    event Caller(address indexed owner);

    // The constructor must pass the necessary arguments to the PriceOracle constructor
    constructor(
        address _lendingToken,
        address _collateralToken,
        address _priceOracle,
        uint256 _ltvRatio,
        uint256 _liquidationPenalty,
        uint256 _initialInterestRate
    ) {
        lendingToken = IERC20(_lendingToken);
        collateralToken = IERC20(_collateralToken);
        priceOracle = PriceOracle(_priceOracle);
        ltvRatio = _ltvRatio;
        liquidationPenalty = _liquidationPenalty;
        interestRate = _initialInterestRate;
    }

    // modifier for only admin function
    modifier onlyAdmin() {
        emit Caller(msg.sender);
        require(msg.sender == admin, "ERC20: caller is not the admin");
        _;
    }

    // Function to adjust the LTV ratio, restricted to the owner
    function setLTVRatio(uint256 _ltvRatio) external onlyAdmin {
        require(
            _ltvRatio > 0 && _ltvRatio <= 1e18,
            "LTV ratio must be between 0 and 1e18 (100%)"
        );
        ltvRatio = _ltvRatio;
    }

    // Function to adjust the liquidation penalty, restricted to the owner
    function setLiquidationPenalty(
        uint256 _liquidationPenalty
    ) external onlyAdmin {
        require(
            _liquidationPenalty > 0 && _liquidationPenalty <= 1e18,
            "Liquidation Penalty must be between 0 and 1e18 (100%)"
        );
        liquidationPenalty = _liquidationPenalty;
    }

    // Function to adjust the interest rate, restricted to the owner
    function setInterestRate(uint256 _interestRate) external onlyAdmin {
        require(
            _interestRate > 0 && _interestRate <= 1e18,
            "Interest rate must be between 0 and 1e18 (100%)"
        );
        interestRate = _interestRate;
    }

    // Function to accrue interest on the user's borrowed balance
    // Internal function that calculates and adds the interest accrued
    // since the user's last interaction with the contract.
    function _accrueInterest(address _user) internal {
        BorrowInfo storage info = borrowInfo[_user];
        if (info.borrowedAmount > 0) {
            // Calculate the time elapsed since the last interest accrual in seconds
            uint256 timeElapsed = block.timestamp - info.lastBorrowTimestamp;

            // Calculate the interest accrued per second
            uint256 interest = (info.borrowedAmount *
                interestRate *
                timeElapsed) / 1e18;

            // Update the borrowed amount in the user's borrow info
            info.borrowedAmount += interest;
        }
        // Update the last borrow timestamp to the current time
        info.lastBorrowTimestamp = block.timestamp;
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

        // _accrueInterest function is called to ensure the interest accrued is up-to-date.
        _accrueInterest(msg.sender);

        // Get the price of the collateral token in terms of the lending token
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the maximum borrowable amount based on the LTV ratio
        uint256 collateralValueInLendingToken = ((collateralBalance[
            msg.sender
        ] * collateralPrice) / 1e18);
        uint256 maxBorrowableAmount = (collateralValueInLendingToken *
            ltvRatio) / 1e18;

        require(
            borrowInfo[msg.sender].borrowedAmount + _amount <=
                maxBorrowableAmount,
            "Borrow amount exceeds collateralized value"
        );

        // Update the user's borrowed balance
        borrowInfo[msg.sender].borrowedAmount += _amount;

        // Transfer the lending token to the user
        lendingToken.transfer(msg.sender, _amount);
    }

    // This function allows users to repay the amount they have borrowed.
    // Once the borrowed amount is repaid, they can withdraw their collateral.
    function repay(uint256 _amount) external {
        require(_amount > 0, "Amount to be repaid must be greater than 0");

        // make sure the accrue interest is up to date
        _accrueInterest(msg.sender);

        BorrowInfo storage info = borrowInfo[msg.sender];
        uint256 totalOwed = info.borrowedAmount + info.interestAccrued;
        require(_amount <= totalOwed, "Repay amount exceeds total debt");

        // Update the user's borrowed balance and interest accrued
        if (_amount >= info.interestAccrued) {
            _amount -= info.interestAccrued;
            info.interestAccrued = 0;
            info.borrowedAmount -= _amount;
        } else {
            info.interestAccrued -= _amount;
        }

        // Transfer the lending token from the user to the contract
        lendingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawCollateral(uint256 _amount) external {
        require(_amount > 0, "Amount withdrawn must be greater than zero");

        // By accruing interest in the withdrawal function, you ensure that the calculations
        // related to the user's debt and collateral are accurate and up-to-date.
        _accrueInterest(msg.sender);

        // Get the price of the collateral token in terms of the lending token
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the value of the remaining collateral after withdrawal
        uint256 remainingCollateralValue = ((collateralBalance[msg.sender] -
            _amount) * collateralPrice) / 1e18;

        // Calculate the maximum allowable borrowed balance based on the LTV ratio
        uint256 maxBorrowableAmountAfterWithdrawal = (remainingCollateralValue *
            ltvRatio) / 1e18;
        require(
            borrowInfo[msg.sender].borrowedAmount <=
                maxBorrowableAmountAfterWithdrawal,
            "Cannot withdraw more collateral"
        );

        // Update the user's collateral balance
        collateralBalance[msg.sender] -= _amount;

        // Transfer the collateral token back to the user
        collateralToken.transfer(msg.sender, _amount);
    }

    function getMaxBorrowableAmount(address _user) external returns (uint256) {
        // Accrue interest on the user's borrow balance
        _accrueInterest(_user);

        uint256 accruedInterest = borrowInfo[_user].interestAccrued;

        uint256 totalDebt = borrowInfo[_user].borrowedAmount + accruedInterest;

        // Retrieve the collateral price
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the value of the collateral in terms of the lending token
        uint256 collateralValueInLendingToken = (collateralBalance[_user] *
            collateralPrice) / 1e18;

        // Calculate the maximum borrowable amount based on the LTV ratio
        uint256 maxBorrowableAmount = (collateralValueInLendingToken *
            ltvRatio) / 1e18;

        // Return the maximum amount that can still be borrowed
        return maxBorrowableAmount - totalDebt;
    }

    function liquidate(address _user) external {
        // Accrue interest on the user's borrow balance
        _accrueInterest(_user);

        uint256 accruedInterest = borrowInfo[_user].interestAccrued;
        uint256 totalDebt = borrowInfo[_user].borrowedAmount + accruedInterest;

        // Retrieve the price of the collateral token relative to the lending token
        uint256 collateralPrice = priceOracle.getPrice(
            address(collateralToken)
        );

        // Calculate the current value of the user's collateral in terms of the lending token
        uint256 collateralValueInLendingToken = (collateralBalance[_user] *
            collateralPrice) / 1e18;

        // Calculate the maximum allowable borrowed balance based on the LTV ratio
        uint256 maxBorrowableAmount = (collateralValueInLendingToken *
            ltvRatio) / 1e18;

        // Check if the user's borrowed amount exceeds the maximum borrowable amount
        require(
            totalDebt > maxBorrowableAmount,
            "User's collateral is sufficient"
        );

        // Get the amount the liquidator needs to repay, which is the user's total debt
        uint256 repaymentAmount = totalDebt;

        // Transfer the repayment amount from the liquidator to the contract.
        // Check if this is succesfull before balancing to zero
        lendingToken.transferFrom(msg.sender, address(this), repaymentAmount);

        // Calculate the liquidation penalty
        uint256 penaltyAmount = (collateralBalance[_user] *
            liquidationPenalty) / 1e18;

        // Calculate the remaining collateral after applying the penalty
        uint256 remainingCollateral = collateralBalance[_user] - penaltyAmount;

        // Reset the user's borrowed and collateral balances to zero to reflect the loan being repaid
        // and the collateral being transferred.
        borrowInfo[_user].borrowedAmount = 0;
        collateralBalance[_user] = 0;

        // Transfer the remaining collateral to the liquidator
        collateralToken.transfer(msg.sender, remainingCollateral);

        // Transfer the penalty amount to the liquidator
        collateralToken.transfer(msg.sender, penaltyAmount);
    }
}
