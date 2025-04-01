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
        address _initialOwner,
        address _factory
    ) public initializer {
        __Ownable_init(_initialOwner);
        factory = _factory;
    }

    /* Main functions */
    function addLiquidity(
        uint amountA,
        uint amountB
    ) external override returns (uint liquidity) {}

    function removeLiquidity(
        uint liquidity
    ) external override returns (uint amountOut, uint amountB) {}

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
        Match.useTransferFrom(
            _tokenAddressIn,
            msg.sender,
            matchAddress,
            _amountIn
        );
        Match.useSwap(matchAddress, amountOut, _tokenAddressOut, msg.sender);
    }
    /* Getter Setter */
}
