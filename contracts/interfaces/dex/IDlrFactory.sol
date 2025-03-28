// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IDlrFactory {
    event DrlMatchCreated(
        address indexed tokenAddressA,
        address indexed tokenAddressB,
        address mapAddress,
        uint
    );

    function getMatch(
        address tokenAddressA,
        address tokenAddressB
    ) external view returns (address matchAddress);

    function createMatch(
        address tokenAddressA,
        address tokenAddressA
    ) external returns (address matchAddress);

    function setFeeAddress(address) external;

    function getFeeAddress() external view returns (address);
}
