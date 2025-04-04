// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/dex/IDlrLiquidity.sol";
import "./libraries/Match.sol";
import "./libraries/Global.sol";

contract DlrLiquidity is IDlrLiquidity, Initializable, OwnableUpgradeable {
    /* State Variables */
    address public factory;

    /* Initialize function */

    function initialize(
        address initialOwner,
        address _factory
    ) public initializer {
        __Ownable_init(initialOwner);
        factory = _factory;
    }

    /* Main functions */
    function addLiquidity(
        address tokenAddressIn1,
        address tokenAddressIn2,
        uint128 amountIn1,
        uint128 amountIn2,
        uint128 amountInMin1,
        uint128 amountInMin2
    ) external returns (uint liquidity) {
        (address tokenAddressA, address tokenAddressB) = Global.orderAddress(
            tokenAddressIn1,
            tokenAddressIn2
        );

        (address matchAddress, uint128 reserveA, uint128 reserveB) = Match
            .getMatchReserves(factory, tokenAddressA, tokenAddressB);

        bool isA1 = tokenAddressIn1 == tokenAddressA;
        (
            uint128 amountA,
            uint128 amountB,
            uint128 amountMinInA,
            uint128 amountMinInB
        ) = isA1
                ? (amountIn1, amountIn2, amountInMin1, amountInMin2)
                : (amountIn2, amountIn1, amountInMin2, amountInMin1);

        if (reserveA == 0 && reserveB == 0) {
            if (amountA == 0 && amountB == 0) {
                revert DlrLiquidity_AmountInZero();
            }
        } else if (reserveA > 0 && reserveB > 0) {
            if (amountA == 0) {
                revert DlrLiquidity_AmountInZero();
            }
            uint128 amountRealB = (amountA * reserveB) / reserveA;
            if (amountRealB <= amountB) {
                if (amountRealB < amountMinInB) {
                    revert DlrLiquidity_RealAmountLessDesired();
                }
                amountB = amountRealB;
            }
            if (amountB == 0) {
                revert DlrLiquidity_AmountInZero();
            }
            uint128 amountRealA = (amountB * reserveA) / reserveB;
            if (!(amountRealA <= amountA && amountRealA >= amountMinInA)) {
                revert DlrLiquidity_RealAmountLessDesired();
            }
            amountA = amountRealA;
        } else {
            revert Dlr_ReserveNotEnough();
        }
        if (
            IDlrFactory(factory).matchAddresses(tokenAddressA, tokenAddressB) ==
            address(0)
        ) {
            IDlrFactory(factory).createMatch(tokenAddressA, tokenAddressB);
        }
        Global.useTransferFrom(
            tokenAddressA,
            msg.sender,
            matchAddress,
            amountA
        );
        Global.useTransferFrom(
            tokenAddressB,
            msg.sender,
            matchAddress,
            amountB
        );
        liquidity = Match.useMint(matchAddress, msg.sender);
    }

    function removeLiquidity(
        address tokenAddressIn1,
        address tokenAddressIn2,
        uint128 liquidity,
        uint128 amountMin1,
        uint128 amountMin2
    ) external returns (uint128 amount1, uint128 amount2) {
        (address matchAddress, address tokenAddressA, ) = Match.getMatchAddress(
            factory,
            tokenAddressIn1,
            tokenAddressIn2
        );
        Global.useTransferFrom(
            matchAddress,
            msg.sender,
            matchAddress,
            liquidity
        );
        (uint128 amountA, uint128 amountB) = Match.useBurn(
            matchAddress,
            msg.sender
        );
        (amount1, amount2) = tokenAddressA == tokenAddressIn1
            ? (amountA, amountB)
            : (amountB, amountA);
        if (amount1 < amountMin1 || amount2 < amountMin2) {
            revert DlrLiquidity_RealAmountLessDesired();
        }
    }

    function swapToken(
        uint128 _amountIn,
        uint128 _amountOutMin,
        address _tokenAddressIn,
        address _tokenAddressOut
    ) external virtual returns (uint128 amountOut) {
        /* Checks */
        if (_tokenAddressIn == address(0) || _tokenAddressOut == address(0)) {
            revert Dlr_AddressZero();
        }
        if (_amountIn == 0) {
            revert DlrLiquidity_AmountInZero();
        }
        (address matchAddress, uint128 reserveIn, uint128 reserveOut) = Match
            .getMatchReserves(factory, _tokenAddressIn, _tokenAddressOut);
        if (reserveIn == 0 || reserveOut == 0) {
            revert Dlr_ReserveNotEnough();
        }
        /* Effects */
        uint128 multiple = reserveOut * _amountIn;
        uint128 reserveInAll = reserveIn + _amountIn;
        amountOut = multiple / reserveInAll;
        if (amountOut < _amountOutMin) {
            revert DlrLiquidity_DesireAmountOutChanged();
        }
        /* Interactions */
        //approver
        Global.useTransferFrom(
            _tokenAddressIn,
            msg.sender,
            matchAddress,
            _amountIn
        );
        Match.useSwap(matchAddress, amountOut, _tokenAddressOut, msg.sender);
    }
    /* Getter Setter */
}
