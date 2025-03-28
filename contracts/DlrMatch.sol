// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./DlrMatchBase.sol";
import "./interfaces/dex/IDlrMatch.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DlrMatch is IDlrMatch, DlrMatchBase, ReentrancyGuard {
    /* State declarations */
    address public tokenAddressA;
    address public tokenAddressB;

    /* Initialize function */
    function initialize(
        address _tokenAddressA,
        address _tokenAddressB
    ) external {
        tokenAddressA = _tokenAddressA;
        tokenAddressB = _tokenAddressB;
    }

    /*Main functions */
    function mint(address _to) external nonReentrant returns (uint liquidity) {
        update();
        emit DlrMatchMint(msg.sender, 1, 2);
    }

    function burn(
        address _to
    ) external nonReentrant returns (uint amountA, uint amountB) {
        update();
        emit DlrMatchBurn(msg.sender, 11, 22, to);
    }

    function swap(
        uint _amountAOut,
        uint _amountBOut,
        address _to,
        bytes calldata _data
    ) external nonReentrant {
        update();
        emit DlrMatchSwap(msg.sender, 111, 222, _amountAOut, _amountBOut, _to);
    }

    /*Private functions */
    function update() private {
        emit DlrMatchSync(1111, 2222);
    }
}
