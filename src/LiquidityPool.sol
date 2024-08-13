// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// The LiquidityPool contract manages two types of ERC20 tokens, allowing users to provide or withdraw liquidity.
contract LiquidityPool {
    // References to the two ERC20 tokens used in this liquidity pool.
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // Reserves of token0 and token1 within the pool (balance of tokens in the liquidity pool).
    uint public reserve0;
    uint public reserve1;

    // Total supply of liquidity pool tokens. These represent a share (liquidity provider tokens) in the pool.
    uint public totalSupply;

    // Mapping from user address to the number of liquidity pool tokens they hold.
    mapping(address => uint) public balanceOf;

    // Constructor initializes the contract with addresses for token0 and token1.
    // These are the ERC20 tokens that will be used in the liquidity pool.
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    // Private function to mint liquidity pool tokens to a user's address.
    // Increases the user's balance and the total supply of pool tokens.
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    // Private function to burn liquidity pool tokens from a user's address.
    // Decreases the user's balance and the total supply of pool tokens.
    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    // Private function to update the reserves of token0 and token1 in the pool.
    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(
        address _tokenIn,
        uint _amountIn
    ) external returns (uint amountOut) {
        // Ensure that the provided token address is either token0 or token1.
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "invalid token"
        );
        // Check that the amount of tokens being swapped is greater than zero.
        require(_amountIn > 0, "amount in = 0");

        // Determine whether the input token is token0 or token1.
        // This helps in setting up the correct token pair and reserves for the swap.
        bool isToken0 = _tokenIn == address(token0);
        // Destructure the appropriate tokens and reserves based on the input token.
        (
            IERC20 tokenIn, // The token being swapped from (input token).
            IERC20 tokenOut, // The token being swapped to (output token).
            uint reserveIn, // The current reserve of the input token in the pool.
            uint reserveOut // The current reserve of the output token in the pool.
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        // Transfer the input tokens from the caller (msg.sender) to the liquidity pool.
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // Apply a 0.3% fee to the input amount.
        // The fee is calculated as (input amount * 997) / 1000.
        uint amountInWithFee = (_amountIn * 997) / 1000;

        // Calculate the output amount using the constant product formula (x * y = k)
        // amountOut (dy) is the amount of output tokens to be sent to the caller.
        // dy = y * dx / x + dx
        // This formula ensures that the product of the reserves remains constant after the swap.
        amountOut =
            (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);

        // Transfer the calculated output tokens to the caller.
        tokenOut.transfer(msg.sender, amountOut);

        // Update the reserves to reflect the new balances of token0 and token1 in the pool.
        _update(
            token0.balanceOf(address(this)), // Updated reserve of token0.
            token1.balanceOf(address(this)) // Updated reserve of token1.
        );
    }

    // External function for users to add liquidity to the pool.
    // Takes in amounts of token0 and token1, calculates how many pool tokens to mint, and updates the reserves.
    function addLiquidity(
        uint _amount0,
        uint _amount1
    ) external returns (uint shares) {
        // Transfer tokens from the user to the pool.
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        // Ensure that the deposited amounts are in proportion to the existing reserves.
        // dy = y / (x * dx) || x / y = dx / dy
        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "x/y != dx/dy");
        }
        // Calculate the number of pool tokens to mint based on the deposited amounts.
        // This condition checks if the pool is empty, meaning no liquidity has been added yet,
        // and therefore there are no existing LP tokens.
        if (totalSupply == 0) {
            // Since there are no existing LP tokens, you need to mint LP tokens for the first liquidity
            // provider based on the initial amounts of tokens added.
            shares = _sqrt(_amount0 * _amount1);
        } else {
            // This condition handles the case when the pool already contains liquidity and LP tokens
            // are already in circulation.
            shares = _min(
                (_amount0 * totalSupply) / reserve0,
                (_amount1 * totalSupply) / reserve1
            );
        }
        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        // Update the reserves in the pool.
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    // External function for users to remove liquidity from the pool.
    // Calculates how many tokens to return based on the amount of pool tokens they want to burn.
    function removeLiquidity(
        uint _shares
    ) external returns (uint amount0, uint amount1) {
        // Get the current balance of token0 and token1 in the pool contract.
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        // Calculate amount of each token to return based on the shares (liquidity pool tokens) being burned.
        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(
            amount0 > 0 && amount1 > 0,
            "Liquidity of tokens must be greater than 0"
        );

        // Burn the pool tokens from the user's balance and update the total supply.
        _burn(msg.sender, _shares);

        // Update the reserves in the pool.
        _update(bal0 - amount0, bal1 - amount1);

        // Transfer the calculated amounts of token0 and token1 back to the user.
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    // Private pure function to calculate the square root of a given value.
    // It is used in the addLiquidity function to calculate the number of shares a user will receive
    // when they add liquidity. It helps ensure that the liquidity provided is fairly represented by the LP tokens.
    // This is used in liquidity pools to calculate LP tokens in a way that balances both token types proportionally
    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Private pure function to return the minimum of two values.
    // Used in liquidity calculations to ensure proportional distribution.
    // Chooses the smaller number when comparing two options.
    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
