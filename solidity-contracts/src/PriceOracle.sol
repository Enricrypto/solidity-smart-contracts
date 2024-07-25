// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LiquidityPool.sol";

contract PriceOracle {
    LiquidityPool public liquidityPool;

    constructor(address _liquidityPool) {
        liquidityPool = LiquidityPool(_liquidityPool);
    }

    // Function to get the price of token0 in terms of token1
    function getToken0Price() external view returns (uint256 price) {
        // Retrieves the current reserves of token0 and token1 from the liquidity pool
        (uint256 reserve0, uint256 reserve1) = getReserves();

        // Ensure reserves are greater than 0 to avoid division by zero
        require(reserve0 > 0 && reserve1 > 0, "Invalid reserves");

        // Calculate the price of token0 in terms of token1
        price = (reserve1 * (10 ** 18)) / reserve0;
    }

    // Function to get the price of token1 in terms of token0
    function getToken1Price() external view returns (uint256 price) {
        // Retrieves the current reserves of token0 and token1 from the liquidity pool
        (uint256 reserve0, uint256 reserve1) = getReserves();

        // Ensure reserves are greater than 0 to avoid division by zero
        require(reserve0 > 0 && reserve1 > 0, "Invalid reserves");

        // Calculate the price of token1 in terms of token0
        price = (reserve0 * (10 ** 18)) / reserve1;
    }

    // Helper function to get reserves from the liquidity pool contract
    function getReserves()
        internal
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        // Retrieve the reserves of token0 and token1 from the liquidity pool
        // reserve0() and reserve1() are called as functions because they are public state variables
        // in the LiquidityPool contract, and Solidity automatically generates getter functions for them
        reserve0 = liquidityPool.reserve0();
        reserve1 = liquidityPool.reserve1();
    }
}
