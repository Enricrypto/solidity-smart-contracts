// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract LiquidityPoolTest is Test {
    LiquidityPool public pool;
    MockERC20 public token0;
    MockERC20 public token1;

    address public owner = address(1);
    address public user = address(2);

    function setUp() public {
        // Deploy mock tokens
        token0 = new MockERC20("Token0", "TK0");
        token1 = new MockERC20("Token1", "TK1");

        // Deploy the liquidity pool contract
        vm.startPrank(owner);
        pool = new LiquidityPool(address(token0), address(token1), 0, 0);
        vm.stopPrank();

        // Mint tokens to the owner and user
        token0.mint(owner, 1000 ether);
        token1.mint(owner, 1000 ether);
        token0.mint(user, 1000 ether);
        token1.mint(user, 1000 ether);

        // Approve tokens for the liquidity pool contract
        vm.startPrank(owner);
        token0.approve(address(pool), type(uint256).max); // Use max allowance for testing
        token1.approve(address(pool), type(uint256).max); // Use max allowance for testing
        vm.stopPrank();

        // Add initial liquidity
        addInitialLiquidity(100 ether, 100 ether);
    }

    function testInitialDeployment() public view {
        assertEq(token0.balanceOf(address(pool)), 100 ether);
        assertEq(token1.balanceOf(address(pool)), 100 ether);
        assertEq(pool.reserve0(), 100 ether);
        assertEq(pool.reserve1(), 100 ether);
    }

    function testAddLiquidity() public {
        vm.startPrank(user);
        token0.approve(address(pool), 100 ether);
        token1.approve(address(pool), 100 ether);
        vm.stopPrank();

        vm.prank(user);
        uint256 shares = pool.addLiquidity(50 ether, 50 ether);

        assertEq(token0.balanceOf(address(pool)), 150 ether);
        assertEq(token1.balanceOf(address(pool)), 150 ether);
        assertEq(pool.reserve0(), 150 ether);
        assertEq(pool.reserve1(), 150 ether);
        assertEq(pool.balanceOf(user), shares);
    }

    function testRemoveLiquidity() public {
        vm.prank(owner);
        pool.removeLiquidity(10 ether);

        assertEq(token0.balanceOf(owner), 10 ether);
        assertEq(token1.balanceOf(owner), 10 ether);
        assertEq(pool.reserve0(), 90 ether);
        assertEq(pool.reserve1(), 90 ether);
        assertEq(pool.balanceOf(owner), 0 ether);
    }

    function testSwap() public {
        vm.startPrank(user);
        token0.approve(address(pool), 10 ether);
        vm.stopPrank();

        vm.prank(user);
        uint256 amountOut = pool.swap(address(token0), 10 ether);

        assertEq(token0.balanceOf(user), 990 ether);
        assertEq(token1.balanceOf(user), amountOut);
        assertEq(pool.reserve0(), 110 ether);
        assertEq(pool.reserve1(), 100 ether - amountOut);
    }

    // Helper function to add initial liquidity to the pool
    function addInitialLiquidity(uint256 amount0, uint256 amount1) internal {
        vm.startPrank(owner);
        pool.addLiquidity(amount0, amount1);
        vm.stopPrank();
    }
}
