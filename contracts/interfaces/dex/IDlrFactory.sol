// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IDlrFactory {
    /*Type declarations*/
    event DrlMatchCreated(
        address indexed _tokenAddressA,
        address indexed _tokenAddressB,
        address _mapAddress,
        uint
    );

    /*Main functions */
    function getMatch(
        address _tokenAddressA,
        address _tokenAddressB
    ) external view returns (address matchAddress);

    function createMatch(
        address _tokenAddressA,
        address _tokenAddressB
    ) external returns (address matchAddress);

    /* Getter Setter */
    function getFeeAddress() external view returns (address);

    function setFeeAddress(address) external;
}
