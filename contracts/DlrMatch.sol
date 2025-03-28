// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {DlrMatchBase} from "./DlrMatchBase.sol";

contract DlrMatch is DlrMatchBase {
    /*Event*/
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external {}
}
