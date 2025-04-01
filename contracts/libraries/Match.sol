// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "../interfaces/dex/IDlrFactory.sol";
import "../interfaces/dex/IDlrMatch.sol";
import "./Global.sol";

library Match {
    function getMatchAddress(
        address _factory,
        address _tokenAddressIn,
        address _tokenAddressOut
    )
        internal
        view
        returns (
            address matchAddress,
            address tokenAddressA,
            address tokenAddressB
        )
    {
        bytes32 matchHash = IDlrFactory(_factory).getMatchHash();
        (tokenAddressA, tokenAddressB) = Global.orderAddress(
            _tokenAddressIn,
            _tokenAddressOut
        );
        matchAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            _factory,
                            keccak256(
                                abi.encodePacked(tokenAddressA, tokenAddressB)
                            ),
                            matchHash
                        )
                    )
                )
            )
        );
    }

    function getMatchReserves(
        address _factory,
        address _tokenAddressIn,
        address _tokenAddressOut
    )
        internal
        view
        returns (address matchAddress, uint128 reserveIn, uint128 reserveOut)
    {
        (address _matchAddress, address tokenAddressA, ) = getMatchAddress(
            _factory,
            _tokenAddressIn,
            _tokenAddressOut
        );
        uint128 reserveA = IDlrMatch(matchAddress).reserveA();
        uint128 reserveB = IDlrMatch(matchAddress).reserveB();

        (uint128 _reserveIn, uint128 _reserveOut) = _tokenAddressIn ==
            tokenAddressA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);
        return (_matchAddress, _reserveIn, _reserveOut);
    }

    function useTransferFrom(
        address _tokenAddress,
        address _from,
        address _to,
        uint128 _value
    ) internal {
        (bool success, bytes memory data) = _tokenAddress.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
        if (!success) {
            revert Dlr_TransferFail();
        }
        if (data.length != 0 || !abi.decode(data, (bool))) {
            revert Dlr_TransferFail();
        }
    }

    function useTransfer(
        address _tokenAddress,
        address _to,
        uint128 _value
    ) internal {
        (bool success, bytes memory data) = _tokenAddress.call(
            abi.encodeWithSelector(IERC20.transfer.selector, _to, _value)
        );
        if (!success) {
            revert Dlr_TransferFail();
        }
        if (data.length != 0 || !abi.decode(data, (bool))) {
            revert Dlr_TransferFail();
        }
    }

    function useSwap(
        address _matchAddress,
        uint128 _amountOut,
        address _tokenAddressOut,
        address _to
    ) internal {
        IDlrMatch(_matchAddress).swap(_amountOut, _tokenAddressOut, _to);
    }
}
