// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IDlrFactory {
    /* Type declarations */
    event DrlMatchCreated(
        address indexed _tokenAddressA,
        address indexed _tokenAddressB,
        address _matchAddress,
        uint _timestamp
    );

    /* Main functions */
    function createMatch(
        address _tokenAddress1,
        address _tokenAddress2
    ) external returns (address matchAddress);

    /* Getter Setter */
    function getFeeAddress() external view returns (address);

    function setFeeAddress(address) external;

    function getMatchHash() external view returns (bytes32);
}
