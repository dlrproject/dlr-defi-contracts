// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDlrLiquidity {
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
        address tokenAddressIn1,
        address tokenAddressIn2,
        uint128 liquidity,
        uint128 amountMin1,
        uint128 amountMin2
    ) external returns (uint128 amount1, uint128 amount2);

    /* Getter Setter */

    function swapToken(
        uint128 _amountIn,
        uint128 _amountOutMin,
        address _tokenAddressIn,
        address _tokenAddressOut
    ) external returns (uint128 amountOut);
}
