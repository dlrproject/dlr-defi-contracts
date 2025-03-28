// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./IDlrMatchBase.sol";

interface IDlrMatch is IDlrMatchBase {
    /*Type declarations*/
    event DlrMatchSwap(
        address indexed sender,
        uint amountAIn,
        uint amountBIn,
        uint amountAOut,
        uint amountBOut,
        address indexed to
    );

    event DlrMatchMint(address indexed sender, uint amountA, uint amountB);
    event DlrMatchBurn(
        address indexed sender,
        uint amountA,
        uint amountB,
        address indexed to
    );
    event DlrMatchSync(uint112 reserveA, uint112 reserveB);

    /* Initialize function */
    function initialize(
        address _tokenAddressA,
        address _tokenAddressB
    ) external;

    /*External functions */
    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amountA, uint amountB);

    function swap(
        uint amountAOut,
        uint amountBOut,
        address to,
        bytes calldata data
    ) external;
}
