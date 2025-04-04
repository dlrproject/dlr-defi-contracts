// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDlrLiquidity {
    event DlrLiquidityInvestment(
        address indexed _sender,
        address indexed _matchAddress,
        address _tokenAddressA,
        address _tokenAddressB,
        uint128 _amountA,
        uint128 _amountB,
        uint _liquidity
    );
    event DlrLiquidityProfit(
        address indexed _sender,
        address indexed _matchAddress,
        address _tokenAddressA,
        address _tokenAddressB,
        uint128 _amountA,
        uint128 _amountB,
        uint _liquidity
    );
    event DlrLiquiditySwapToken(
        address indexed _sender,
        address indexed _matchAddress,
        address _tokenAddressIn,
        address _tokenAddressOut,
        uint128 _amountIn,
        uint128 _amountOut
    );

    /* Type declarations */
    /* Initialize function */
    function initialize(address _initialOwner, address _factory) external;

    /* Main functions */
    function addLiquidity(
        address _tokenAddressIn1,
        address _tokenAddressIn2,
        uint128 _amountIn1,
        uint128 _amountIn2,
        uint128 _amountInMin1,
        uint128 _amountInMin2
    ) external returns (uint liquidity);

    function removeLiquidity(
        address _tokenAddressIn1,
        address _tokenAddressIn2,
        uint128 _liquidity,
        uint128 _amountMin1,
        uint128 _amountMin2
    ) external returns (uint128 amount1, uint128 amount2);

    function swapToken(
        uint128 _amountIn,
        uint128 _amountOutMin,
        address _tokenAddressIn,
        address _tokenAddressOut
    ) external returns (uint128 amountOut);
    /* Getter Setter */
}
