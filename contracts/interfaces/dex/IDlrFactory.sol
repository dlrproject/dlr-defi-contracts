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

//   /******************************************************************/
//     /**
//      * @dev The contract is already initialized.
//      */
//     error InvalidInitialization();

//     /**
//      * @dev The contract is not initializing.
//      */
//     error NotInitializing();

//     /**
//      * @dev Triggered when the contract has been initialized or reinitialized.
//      */
//     event Initialized(uint64 version);

//     /**
//      * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
//      * `onlyInitializing` functions can be used to initialize parent contracts.
//      *
//      * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
//      * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
//      * production.
//      *
//      * Emits an {Initialized} event.
//      *
//      /******************************************************************/

//     /******************************************************************/
//     /**
//      * @dev Emitted when the pause is triggered by `account`.
//      */
//     event Paused(address account);

//     /**
//      * @dev Emitted when the pause is lifted by `account`.
//      */
//     event Unpaused(address account);

//     /**
//      * @dev The operation failed because the contract is paused.
//      */
//     error EnforcedPause();

//     /**
//      * @dev The operation failed because the contract is not paused.
//      */
//     error ExpectedPause();

//     /**
//      * @dev Initializes the contract in unpaused state.
//      */

//     /******************************************************************/

//     /******************************************************************/

//     /**
//      * @dev The caller account is not authorized to perform an operation.
//      */
//     error OwnableUnauthorizedAccount(address account);

//     /**
//      * @dev The owner is not a valid owner account. (eg. `address(0)`)
//      */
//     error OwnableInvalidOwner(address owner);

//     event OwnershipTransferred(
//         address indexed previousOwner,
//         address indexed newOwner
//     );
//     /******************************************************************/
