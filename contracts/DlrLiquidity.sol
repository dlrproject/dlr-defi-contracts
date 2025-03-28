// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./interfaces/dex/IDlrLiquidity.sol";

contract DlrLiquidity is IDlrLiquidity {
    /* State Variables */
    /* Initialize function */
    /* Main functions */
    function addLiquidity(
        uint amountA,
        uint amountB
    ) external override returns (uint liquidity) {}

    function removeLiquidity(
        uint liquidity
    ) external override returns (uint amountA, uint amountB) {}
    /* Getter Setter */
}
