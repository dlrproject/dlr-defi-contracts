// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/dex/IDlrMatch.sol";
import "./libraries/Match.sol";
import "./libraries/Global.sol";

contract DlrMatch is IDlrMatch, ReentrancyGuard, Ownable {
    /* State declarations */
    address public tokenAddressA;
    address public tokenAddressB;
    uint128 public reserveA;
    uint128 public reserveB;
    uint256 public kLast;

    /* Initialize function */
    function initialize(
        address _tokenAddressA,
        address _tokenAddressB
    ) external onlyOwner {
        tokenAddressA = _tokenAddressA;
        tokenAddressB = _tokenAddressB;
    }

    /* Main functions */
    function mint(address _to) external nonReentrant returns (uint liquidity) {
        // update();
        emit DlrMatchMint(msg.sender, 1, 2);
    }

    function burn(
        address _to
    ) external nonReentrant returns (uint amountA, uint amountB) {
        // update();

        emit DlrMatchBurn(msg.sender, 11, 22, _to);
    }

    function swap(
        uint128 _amountOut,
        address _tokenAddressOut,
        address _to
    ) external nonReentrant {
        if (_to == address(0)) {
            revert Dlr_AddressZero();
        }
        if (_tokenAddressOut == address(0)) {
            revert Dlr_AddressZero();
        }
        if (_amountOut == 0) {
            revert DlrMatch_AmountOutZero();
        }
        bool isAout = _tokenAddressOut == tokenAddressA;
        (
            address tokenAddressOut,
            uint128 reserveOut,
            address tokenAddressIn,
            uint128 reserveIn,
            uint128 amountOut
        ) = isAout
                ? (tokenAddressA, reserveA, tokenAddressB, reserveB, _amountOut)
                : (
                    tokenAddressB,
                    reserveB,
                    tokenAddressA,
                    reserveA,
                    _amountOut
                );

        if (amountOut > reserveOut) {
            revert Dlr_ReserveNotEnough();
        }
        Match.useTransfer(tokenAddressOut, _to, amountOut);
        uint balanceIn = IERC20(tokenAddressIn).balanceOf(address(this));
        uint balanceOut = IERC20(tokenAddressOut).balanceOf(address(this));
        uint128 amountIn = balanceIn > reserveIn
            ? uint128(balanceIn - reserveIn)
            : uint128(0);
        if ((balanceIn - amountIn) * balanceOut < reserveIn * reserveOut) {
            revert DlrLiquidity_KValueChangedLess();
        }
        (
            uint128 amountAIn,
            uint128 amountBIn,
            uint128 amountAOut,
            uint128 amountBOut
        ) = update(isAout, amountIn, amountOut, balanceIn, balanceOut);
        emit DlrMatchSwap(
            msg.sender,
            amountAIn,
            amountBIn,
            amountAOut,
            amountBOut,
            _to
        );
    }

    /* Private functions */
    function update(
        bool isAout,
        uint128 amountIn,
        uint128 amountOut,
        uint balanceIn,
        uint balanceOut
    )
        private
        returns (
            uint128 amountAIn,
            uint128 amountBIn,
            uint128 amountAOut,
            uint128 amountBOut
        )
    {
        uint128 _reserveA;
        uint128 _reserveB;
        if (isAout) {
            _reserveA = uint128(balanceOut);
            _reserveB = uint128(balanceIn);
            amountAIn = uint128(0);
            amountBOut = uint128(0);
            amountAOut = amountOut;
            amountBIn = amountIn;
        } else {
            _reserveA = uint128(balanceIn);
            _reserveB = uint128(balanceOut);
            amountAIn = amountIn;
            amountBOut = amountAOut;
            amountAOut = uint128(0);
            amountBIn = uint128(0);
        }
        kLast = uint256(_reserveB * _reserveB);
        reserveA = _reserveA;
        reserveB = _reserveB;
        emit DlrMatchSync(_reserveB, _reserveB);
    }

    /* Getter Setter */
    function getPriceA() public view returns (uint priceA) {
        priceA = (reserveB / reserveA);
    }

    function getPriceB() public view returns (uint priceB) {
        priceB = (reserveA / reserveB);
    }

    /************************ERC20************************/
    string public constant name = "DLR Match Token";
    string public constant symbol = "DLR";
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor() Ownable(msg.sender) {}

    function approve(
        address spender,
        uint value
    ) external override nonReentrant returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transfer(
        address to,
        uint value
    ) external override nonReentrant returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external override nonReentrant returns (bool) {
        if (allowance[from][msg.sender] < value) {
            revert DlrMatch_ApproveNotEnough();
        }
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    /************************ERC20************************/
}
