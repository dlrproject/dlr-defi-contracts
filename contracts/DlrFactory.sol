// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/dex/IDlrFactory.sol";
import "./libraries/Global.sol";
import "./DlrMatch.sol";

contract DlrFactory is IDlrFactory, PausableUpgradeable, OwnableUpgradeable {
    /* State Variables */
    bytes private matchBytecode;
    bytes32 public matchHash;

    address public feeAddress;
    address[] public contractAddersses;
    mapping(address => mapping(address => address)) public matchAddresses;

    /* Initialize function */
    function initialize(address initialOwner) public initializer {
        __Pausable_init();
        __Ownable_init(initialOwner);
        matchBytecode = type(DlrMatch).creationCode;
        matchHash = keccak256(matchBytecode);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* Main functions */
    function createMatch(
        address _tokenAddress1,
        address _tokenAddress2
    ) external returns (address matchAddress) {
        /* Checks */
        if (_tokenAddress1 == _tokenAddress2) {
            revert DlrFactory_TokenAddressSame();
        }
        if (matchAddresses[_tokenAddress1][_tokenAddress2] != address(0)) {
            revert DlrFactory_MatchAlreadyExists();
        }
        (address tokenAddressA, address tokenAddressB) = Global.orderAddress(
            _tokenAddress1,
            _tokenAddress2
        );
        if (tokenAddressA == address(0)) {
            revert Dlr_AddressZero();
        }
        /* Effects */
        bytes32 salt = keccak256(
            abi.encodePacked(tokenAddressA, tokenAddressB)
        );
        bytes memory bytecode = matchBytecode;
        assembly {
            matchAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        matchAddresses[tokenAddressA][tokenAddressB] = matchAddress;
        matchAddresses[tokenAddressA][tokenAddressB] = matchAddress;
        contractAddersses.push(matchAddress);

        /* Interactions */
        IDlrMatch(matchAddress).initialize(tokenAddressA, tokenAddressB);

        emit DrlMatchCreated(
            tokenAddressA,
            tokenAddressB,
            matchAddress,
            block.timestamp
        );
    }

    /* Getter Setter */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        if (_feeAddress == address(0)) {
            revert Dlr_AddressZero();
        }
        feeAddress = _feeAddress;
    }

    function getFeeAddress() external view returns (address) {
        return feeAddress;
    }

    function getMatchHash() external view returns (bytes32) {
        return matchHash;
    }
}
