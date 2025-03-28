// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./DlrMatchBase.sol";
import "./interfaces/dex/IDrlMatch.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DlrMatch is IDrlMatch, DlrMatchBase, ReentrancyGuard {
    /* State declarations */
    address public s_tokenAddressA;
    address public s_tokenAddressB;

    /* Initialize function */
    function initialize(
        address _tokenAddressA,
        address _tokenAddressB
    ) external {
        s_tokenAddressA = _tokenAddressA;
        s_tokenAddressB = _tokenAddressB;
    }

    /*External functions */
    function mint(address to) external nonReentrant returns (uint liquidity) {
        update();
        emit DlrMatchMint(msg.sender, 1, 2);
    }

    function burn(
        address to
    ) external nonReentrant returns (uint amountA, uint amountB) {
        update();
        emit DlrMatchBurn(msg.sender, 11, 22, to);
    }

    function swap(
        uint amountAOut,
        uint amountBOut,
        address to,
        bytes calldata data
    ) external nonReentrant {
        update();
        emit DlrMatchSwap(msg.sender, 111, 222, amountAOut, amountBOut, to);
    }

    /*Private functions */
    function update() private {
        emit DlrMatchSync(1111, 2222);
    }
}
