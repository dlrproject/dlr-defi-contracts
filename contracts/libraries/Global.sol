// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
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
}
