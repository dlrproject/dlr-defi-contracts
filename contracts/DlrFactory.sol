// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./DlrMatch.sol";
import "./interfaces/dex/IDlrFactory.sol";

contract DlrFactory is
    IDlrFactory,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    /*State Variables*/
    address public s_feeAddress;
    address[] public s_matchAddersses;
    mapping(address => mapping(address => address)) public s_matchMaps;

    /*
    initialize
    */
    function initialize(address initialOwner) public initializer {
        __Pausable_init();
        __Ownable_init(initialOwner);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function createMatch(
        address tokenAddressA,
        address tokenAddressB
    ) external returns (address matchAddress) {
        bytes32 salt = keccak256(
            abi.encodePacked(tokenAddressA, tokenAddressB)
        );
        bytes memory bytecode = type(DlrMatch).creationCode;
        assembly {
            matchAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IDlrMatch(matchAddress).initialize(tokenAddressA, tokenAddressB);
        emit DrlMatchCreated(
            tokenAddressA,
            tokenAddressB,
            matchAddress,
            block.timestamp
        );
    }

    /*
        view functions
    */

    function getMatch(
        address tokenAddressA,
        address tokenAddressB
    ) external view returns (address matchAddress) {
        matchAddress = s_matchMaps[tokenAddressA][tokenAddressB];
    }

    function setFeeAddress(address feeAddress) external {
        s_feeAddress = feeAddress;
    }

    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }
}
