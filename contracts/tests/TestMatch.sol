// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "../libraries/Match.sol";

import "../DlrMatch.sol";

contract TestMatch {
    function getMatchAddress(
        address _factory,
        address _tokenAddress1,
        address _tokenAddress2
    )
        public
        view
        returns (
            address matchAddress,
            address tokenAddressA,
            address tokenAddressB
        )
    {
        (matchAddress, tokenAddressA, tokenAddressB) = Match.getMatchAddress(
            _factory,
            _tokenAddress1,
            _tokenAddress2
        );
    }

    function getMatchHash() public pure returns (bytes32 matchHash) {
        bytes memory matchBytecode = type(DlrMatch).creationCode;
        matchHash = keccak256(matchBytecode);
    }
}
