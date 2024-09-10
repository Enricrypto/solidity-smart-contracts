// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
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
        pool = new LiquidityPool(address(token0), address(token1));
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
        vm.startPrank(owner);
        pool.addLiquidity(100 ether, 100 ether);
        vm.stopPrank();
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
        // Use the shares corresponding to the initial liquidity
        uint256 removeShares = 10 ether;
        uint256 ownerInitialShares = pool.balanceOf(owner);

        // Ensure the owner has the correct amount of liquidity pool tokens
        assertEq(ownerInitialShares, 100 ether, "Owner's initial shares are incorrect");

        // Calculate expected amounts of token0 and token1 to be received
        uint256 expectedToken0Amount = (removeShares * token0.balanceOf(address(pool))) / ownerInitialShares;
        uint256 expectedToken1Amount = (removeShares * token1.balanceOf(address(pool))) / ownerInitialShares;

        // Store the owner's initial token balances
        uint256 initialOwnerToken0Balance = token0.balanceOf(owner);
        uint256 initialOwnerToken1Balance = token1.balanceOf(owner);

        // Remove liquidity
        vm.prank(owner);
        (uint256 amount0, uint256 amount1) = pool.removeLiquidity(removeShares);

        // Verify the returned amounts
        assertEq(amount0, expectedToken0Amount, "Returned Token 0 amount is incorrect");
        assertEq(amount1, expectedToken1Amount, "Returned Token 1 amount is incorrect");

        // Verify the owner's balances
        assertEq(
            token0.balanceOf(owner),
            initialOwnerToken0Balance + expectedToken0Amount,
            "Owner's Token 0 balance is incorrect"
        );
        assertEq(
            token1.balanceOf(owner),
            initialOwnerToken1Balance + expectedToken1Amount,
            "Owner's Token 1 balance is incorrect"
        );

        // Verify the pool's reserves after liquidity removal
        uint256 newReserve0 = pool.reserve0();
        uint256 newReserve1 = pool.reserve1();

        assertEq(newReserve0, 100 ether - expectedToken0Amount, "Reserve of Token 0 is not correct");
        assertEq(newReserve1, 100 ether - expectedToken1Amount, "Reserve of Token 1 is not correct");

        // Verify the owner's remaining pool balance
        uint256 expectedRemainingShares = ownerInitialShares - removeShares;
        assertEq(pool.balanceOf(owner), expectedRemainingShares, "Owner's remaining pool balance is incorrect");
    }

    function testSwap() public {
        // Check user's initial token balances
        uint256 initialUserToken0Balance = token0.balanceOf(user);
        uint256 initialUserToken1Balance = token1.balanceOf(user);
        uint256 amountToWithdraw = 10 ether;

        vm.startPrank(user);
        token0.approve(address(pool), amountToWithdraw);
        vm.stopPrank();

        vm.prank(user);
        uint256 amountOut = pool.swap(address(token0), amountToWithdraw);

        // User's token0 balance should decrease by amountToWithdraw
        assertEq(
            token0.balanceOf(user), initialUserToken0Balance - amountToWithdraw, "Balance of token 0 is not correct"
        );

        // User's token1 balance should increase by amountOut
        assertEq(token1.balanceOf(user), initialUserToken1Balance + amountOut, "Balance of token 1 is not correct");
        assertEq(pool.reserve0(), 110 ether, "Reserve of token 0 is not correct");
        assertEq(pool.reserve1(), 100 ether - amountOut, "Reserve of token 1 is not correct");
    }

    // Helper function to add initial liquidity to the pool
    function addInitialLiquidity(uint256 amount0, uint256 amount1) internal {
        vm.startPrank(owner);
        pool.addLiquidity(amount0, amount1);
        vm.stopPrank();
    }
}
