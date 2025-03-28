// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/dex/IDlrMatchBase.sol";

contract DlrMatchBase is IDlrMatchBase, ReentrancyGuard {
    function name() external pure returns (string memory) {}

    function symbol() external pure returns (string memory) {}

    function decimals() external pure returns (uint8) {}

    function totalSupply() external view returns (uint) {}

    function balanceOf(address owner) external view returns (uint) {}

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint) {}

    function approve(
        address spender,
        uint value
    ) external override returns (bool) {}

    function transfer(
        address to,
        uint value
    ) external override returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint value
    ) external override returns (bool) {}

    function DOMAIN_SEPARATOR() external view returns (bytes32) {}

    function PERMIT_TYPEHASH() external pure returns (bytes32) {}

    function nonces(address owner) external view returns (uint) {}

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {}
}
