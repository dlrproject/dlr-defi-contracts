// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "../interfaces/dex/IDlrFactory.sol";
import "../interfaces/dex/IDlrMatch.sol";
import "./Global.sol";

library Match {
    function getMatchAddress(
        address _factory,
        address _tokenAddress1,
        address _tokenAddress2
    )
        internal
        view
        returns (
            address matchAddress,
            address tokenAddressA,
            address tokenAddressB
        )
    {
        (tokenAddressA, tokenAddressB) = Global.orderAddress(
            _tokenAddress1,
            _tokenAddress2
        );
        bytes32 matchHash = IDlrFactory(_factory).getMatchHash();
        matchAddress = address(
            uint160(
                uint256(
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
        address _tokenAddress1,
        address _tokenAddress2
    )
        internal
        view
        returns (address matchAddress, uint128 reserve1, uint128 reserve2)
    {
        (address _matchAddress, address tokenAddressA, ) = getMatchAddress(
            _factory,
            _tokenAddress1,
            _tokenAddress2
        );
        uint128 reserveA = IDlrMatch(_matchAddress).reserveA();
        uint128 reserveB = IDlrMatch(_matchAddress).reserveB();
        matchAddress = _matchAddress;
        (reserve1, reserve2) = _tokenAddress1 == tokenAddressA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);
    }

    function useSwap(
        address _matchAddress,
        uint128 _amountOut,
        address _tokenAddressOut,
        address _to
    ) internal {
        IDlrMatch(_matchAddress).swap(_amountOut, _tokenAddressOut, _to);
    }

    function useMint(
        address _matchAddress,
        address _to
    ) internal returns (uint128 liquidity) {
        liquidity = IDlrMatch(_matchAddress).mint(_to);
    }

    function useBurn(
        address _matchAddress,
        address _to
    ) internal returns (uint128 amountA, uint128 amountB) {
        (amountA, amountB) = IDlrMatch(_matchAddress).burn(_to);
    }
}
