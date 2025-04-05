// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/dex/IDlrLiquidity.sol";
import "./libraries/Match.sol";
import "./libraries/Global.sol";

contract DlrLiquidity is IDlrLiquidity, Initializable, OwnableUpgradeable {
    using Global for uint256;
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
    ) external returns (uint128 liquidity) {
        (address tokenAddressA, address tokenAddressB) = Global.orderAddress(
            tokenAddressIn1,
            tokenAddressIn2
        );

        (address matchAddress, uint256 reserveA, uint256 reserveB) = Match
            .getMatchReserves(factory, tokenAddressA, tokenAddressB);

        bool isA1 = tokenAddressIn1 == tokenAddressA;
        (
            uint256 amountA,
            uint256 amountB,
            uint256 amountMinInA,
            uint256 amountMinInB
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
            uint256 amountRealB = (amountA.tryMul(reserveB)).tryDiv(reserveA);
            if (amountRealB <= amountB) {
                if (amountRealB < amountMinInB) {
                    revert DlrLiquidity_RealAmountLessDesired();
                }
                amountB = amountRealB;
            }
            if (amountB == 0) {
                revert DlrLiquidity_AmountInZero();
            }
            uint256 amountRealA = (amountB.tryMul(reserveA)).tryDiv(reserveB);
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
        emit DlrLiquidityInvestment(
            msg.sender,
            matchAddress,
            amountA.toUint128(),
            amountB.toUint128(),
            liquidity
        );
    }

    function removeLiquidity(
        address _tokenAddressIn1,
        address _tokenAddressIn2,
        uint128 _liquidity,
        uint128 _amountMin1,
        uint128 _amountMin2
    ) external returns (uint128 amount1, uint128 amount2) {
        (address matchAddress, address tokenAddressA, ) = Match.getMatchAddress(
            factory,
            _tokenAddressIn1,
            _tokenAddressIn2
        );
        Global.useTransferFrom(
            matchAddress,
            msg.sender,
            matchAddress,
            _liquidity
        );
        (uint128 amountA, uint128 amountB) = Match.useBurn(
            matchAddress,
            msg.sender
        );
        (amount1, amount2) = tokenAddressA == _tokenAddressIn1
            ? (amountA, amountB)
            : (amountB, amountA);
        if (amount1 < _amountMin1 || amount2 < _amountMin2) {
            revert DlrLiquidity_RealAmountLessDesired();
        }
        emit DlrLiquidityProfit(
            msg.sender,
            matchAddress,
            amountA,
            amountB,
            _liquidity
        );
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
        (address matchAddress, uint256 reserveIn, uint256 reserveOut) = Match
            .getMatchReserves(factory, _tokenAddressIn, _tokenAddressOut);
        if (reserveIn == 0 || reserveOut == 0) {
            revert Dlr_ReserveNotEnough();
        }
        /* Effects */
        uint256 multiple = reserveOut.tryMul(_amountIn);
        uint256 reserveInAll = reserveIn.tryAdd(_amountIn);
        amountOut = multiple.tryDiv(reserveInAll).toUint128();
        if (amountOut < _amountOutMin) {
            revert DlrLiquidity_DesireAmountOutChanged();
        }
        /* Interactions */
        //approver
        // Global.useApprove(_tokenAddressIn, msg.sender, matchAddress, _amountIn);
        Global.useTransferFrom(
            _tokenAddressIn,
            msg.sender,
            matchAddress,
            _amountIn
        );

        Match.useSwap(matchAddress, amountOut, _tokenAddressOut, msg.sender);

        emit DlrLiquiditySwapToken(
            msg.sender,
            matchAddress,
            _tokenAddressIn,
            _tokenAddressOut,
            _amountIn,
            amountOut
        );
    }
    /* Getter Setter */
}
