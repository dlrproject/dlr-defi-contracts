// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Dlr_TransferFail();
error Dlr_AddressZero();
error Dlr_ReserveNotEnough();
error DlrMatch_AmountOutZero();
error DlrMatch_ApproveNotEnough();
error DlrMatch_SwapToAddressNotMatch();

error DlrFactory_TokenAddressSame();
error DlrFactory_MatchAlreadyExists();

error DlrLiquidity_DesireAmountOutChanged();
error DlrLiquidity_AmountInZero();
error DlrLiquidity_KValueChangedLess();

library Global {
    function orderAddress(
        address a,
        address b
    ) internal pure returns (address, address) {
        (a, b) = a < b ? (a, b) : (b, a);
        return (a, b);
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
}
