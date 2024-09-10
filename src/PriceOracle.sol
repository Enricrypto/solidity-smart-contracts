// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LiquidityPool.sol";

contract PriceOracle {
    LiquidityPool public liquidityPool;
    address public token0;
    address public token1;

    constructor(address _liquidityPool, address _token0, address _token1) {
        liquidityPool = LiquidityPool(_liquidityPool);
        token0 = _token0;
        token1 = _token1;
    }

    // Function to get the price of a given token in terms of the other token
    function getPrice(address _token) external view returns (uint256 price) {
        // Retrieves the current reserves of token0 and token1 from the liquidity pool
        (uint256 reserve0, uint256 reserve1) = getReserves();

        // Ensure reserves are greater than 0 to avoid division by zero
        require(reserve0 > 0 && reserve1 > 0, "Invalid reserves");

        if (_token == token0) {
            // Calculate the price of token0 in terms of token1
            price = (reserve1 * 1e18) / reserve0;
        } else if (_token == token1) {
            // Calculate the price of token1 in terms of token0
            price = (reserve0 * 1e18) / reserve1;
        } else {
            revert("Invalid token address");
        }
    }

    // Helper function to get reserves from the liquidity pool contract
    function getReserves() internal view returns (uint256 reserve0, uint256 reserve1) {
        // Retrieve the reserves of token0 and token1 from the liquidity pool
        // reserve0() and reserve1() are called as functions because they are public state variables
        // in the LiquidityPool contract, and Solidity automatically generates getter functions for them
        reserve0 = liquidityPool.reserve0();
        reserve1 = liquidityPool.reserve1();
    }
}
