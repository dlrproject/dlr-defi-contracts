// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./DlrMatch.sol";
import "./interfaces/dex/IDlrFactory.sol";

error DlrFactory_TokenAddressSame();
error DlrFactory_TokenAddressZero();
error DlrFactory_MatchAlreadyExists();

contract DlrFactory is IDlrFactory, PausableUpgradeable, OwnableUpgradeable {
    /* State Variables */
    address public feeAddress;
    address[] public contractAddersses;
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
    function createMatch(
        address _tokenAddressA,
        address _tokenAddressB
    ) external returns (address matchAddress) {
        /* Checks */
        if (_tokenAddressA == _tokenAddressB) {
            revert DlrFactory_TokenAddressSame();
        }
        if (matchAddresses[_tokenAddressA][_tokenAddressB] != address(0)) {
            revert DlrFactory_MatchAlreadyExists();
        }
        (_tokenAddressA, _tokenAddressB) = _tokenAddressA < _tokenAddressB
            ? (_tokenAddressA, _tokenAddressB)
            : (_tokenAddressB, _tokenAddressA);
        if (_tokenAddressA == address(0)) {
            revert DlrFactory_TokenAddressZero();
        }

        /* Effects */
        bytes32 salt = keccak256(
            abi.encodePacked(_tokenAddressA, _tokenAddressB)
        );
        bytes memory bytecode = type(DlrMatch).creationCode;

        assembly {
            matchAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        matchAddresses[_tokenAddressA][_tokenAddressB] = matchAddress;
        matchAddresses[_tokenAddressB][_tokenAddressA] = matchAddress;
        contractAddersses.push(matchAddress);

        /* Interactions */
        IDlrMatch(matchAddress).initialize(_tokenAddressA, _tokenAddressB);

        emit DrlMatchCreated(
            _tokenAddressA,
            _tokenAddressB,
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
