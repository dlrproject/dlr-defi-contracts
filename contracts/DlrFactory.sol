// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/dex/IDLRFactory.sol";

contract DLRFactory is
    IDLRFactory,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    /*Storage Variables*/
    address storage  s_feeAddress; 
    address[] storage s_matchAddersses;
    mapping(address => mapping(address => address)) storage s_matchMaps;



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
        address tokenAddressA
    ) external returns (address matchAddress){

     emit DrlMatchCreated(tokenAddressA, tokenAddressB, matchAddress, block.timestamp);   
    }




    /*
        view functions
    */

  function getMatch(
        address tokenAddressA,
        address tokenAddressB
    ) external view returns (address matchAddress){
        matchAddress  = s_matchMaps[tokenAddressA][tokenAddressB]; 
    }


    function setFeeAddress(address) external;

    function getFeeAddress() external view returns (address);



   
}
