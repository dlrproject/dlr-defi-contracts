// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDlrMatch is IERC20 {
    /* Type declarations */
    event DlrMatchSwap(
        address indexed _sender,
        uint128 _amountAIn,
        uint128 _amountBIn,
        uint128 _amountAOut,
        uint128 _amountBOut,
        address indexed _to
    );

    event DlrMatchMint(
        address indexed _sender,
        uint128 _amountA,
        uint128 _amountB
    );
    event DlrMatchBurn(
        address indexed _sender,
        uint128 _amountA,
        uint128 _amountB,
        address indexed _to
    );
    event DlrMatchSync(uint128 reserveA, uint128 reserveB);

    /* Initialize function */
    function initialize(
        address _tokenAddressA,
        address _tokenAddressB
    ) external;

    /* Main functions */
    function mint(address _to) external returns (uint128 liquidity);

    function burn(
        address _to
    ) external returns (uint128 amountA, uint128 amountB);

    function swap(
        uint128 _amountOut,
        address _tokenAddressOut,
        address _to
    ) external;

    function skim(address to) external;

    function sync() external;

    /* Gettter Setter */
    function kLast() external view returns (uint256);

    function reserveA() external view returns (uint128);

    function reserveB() external view returns (uint128);

    function getPriceA() external view returns (uint128);

    function getPriceB() external view returns (uint128);

    function tokenAddressA() external view returns (address);

    function tokenAddressB() external view returns (address);

    /************************ERC20************************/
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    /************************ERC20************************/
}
