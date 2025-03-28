// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./IDlrMatchBase.sol";

interface IDlrMatch is IDlrMatchBase {
    /* Type declarations */
    event DlrMatchSwap(
        address indexed _sender,
        uint _amountAIn,
        uint _amountBIn,
        uint _amountAOut,
        uint _amountBOut,
        address indexed _to
    );

    event DlrMatchMint(address indexed _sender, uint _amountA, uint _amountB);
    event DlrMatchBurn(
        address indexed _sender,
        uint _amountA,
        uint _amountB,
        address indexed _to
    );
    event DlrMatchSync(uint112 reserveA, uint112 reserveB);

    /* Initialize function */
    function initialize(
        address _tokenAddressA,
        address _tokenAddressB
    ) external;

    /* Main functions */
    function mint(address _to) external returns (uint liquidity);

    function burn(address _to) external returns (uint amountA, uint amountB);

    function swap(
        uint _amountAOut,
        uint _amountBOut,
        address _to,
        bytes calldata _data
    ) external;
}
