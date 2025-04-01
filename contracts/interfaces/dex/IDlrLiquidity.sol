// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDlrLiquidity {
    /* Type declarations */

    /* Main functions */
    function addLiquidity(
        uint amountA,
        uint amountB
    ) external returns (uint liquidity);

    function removeLiquidity(
        uint liquidity
    ) external returns (uint amountA, uint amountB);

    /* Getter Setter */
}
