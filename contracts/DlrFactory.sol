// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./DlrMatch.sol";
import "./interfaces/dex/IDlrFactory.sol";

contract DlrFactory is IDlrFactory, PausableUpgradeable, OwnableUpgradeable {
    /* State Variables */
    address public feeAddress;
    address[] public tokenAddersses;
    mapping(address => mapping(address => address)) public matchAddresses;

    /* Initialize function */
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

    /* Main functions */
    function getMatch(
        address _tokenAddressA,
        address _tokenAddressB
    ) external view returns (address matchAddress) {
        matchAddress = matchAddresses[_tokenAddressA][_tokenAddressB];
    }

    function createMatch(
        address _tokenAddressA,
        address _tokenAddressB
    ) external returns (address matchAddress) {
        bytes32 salt = keccak256(
            abi.encodePacked(_tokenAddressA, _tokenAddressB)
        );
        bytes memory bytecode = type(DlrMatch).creationCode;
        assembly {
            matchAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IDlrMatch(matchAddress).initialize(_tokenAddressA, _tokenAddressA);
        emit DrlMatchCreated(
            _tokenAddressA,
            _tokenAddressA,
            matchAddress,
            block.timestamp
        );
    }

    /* Getter Setter */
    function setFeeAddress(address _feeAddress) external {
        feeAddress = _feeAddress;
    }

    function getFeeAddress() external view returns (address) {
        return feeAddress;
    }
}
