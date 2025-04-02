// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDlrLiquidity {
    /* Type declarations */
    /* Initialize function */
    function initialize(address _initialOwner, address _factory) external;

    /* Main functions */
    function addLiquidity(
        address tokenAddressIn1,
        address tokenAddressIn2,
        uint128 amountIn1,
        uint128 amountIn2,
        uint128 amountInMin1,
        uint128 amountInMin2
    ) external returns (uint liquidity);

    function removeLiquidity(
        uint liquidity
    ) external returns (uint amountA, uint amountB);

    /* Getter Setter */

    function swapToken(
        uint128 _amountIn,
        uint128 _amountOutMin,
        address _tokenAddressIn,
        address _tokenAddressOut
    ) external returns (uint128 amountOut);
}
