// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/dex/IDlrMatch.sol";
import "./libraries/Global.sol";

contract DlrMatch is IDlrMatch, ReentrancyGuard, Ownable {
    using Math for uint;
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
        uint balanceA = IERC20(tokenAddressA).balanceOf(address(this));
        uint balanceB = IERC20(tokenAddressB).balanceOf(address(this));
        uint128 amountA = uint128(balanceA - reserveA);
        uint128 amountB = uint128(balanceB - reserveB);
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            uint liquidityA = (amountA * _totalSupply) / reserveA;
            uint liquidityB = (amountB * _totalSupply) / reserveB;
            liquidity = liquidityA > liquidityB ? liquidityB : liquidityA;
        }
        _mint(_to, liquidity);
        _update(uint128(balanceA), uint128(balanceB));
        emit DlrMatchMint(_to, amountA, amountB);
    }

    function burn(
        address _to
    ) external nonReentrant returns (uint128 amountA, uint128 amountB) {
        uint balanceA = IERC20(tokenAddressA).balanceOf(address(this));
        uint balanceB = IERC20(tokenAddressB).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        amountA = uint128((liquidity * balanceA) / totalSupply); // using balances ensures pro-rata distribution
        amountB = uint128((liquidity * balanceB) / totalSupply);

        _burn(address(this), liquidity);
        Global.useTransfer(tokenAddressA, _to, amountA);
        Global.useTransfer(tokenAddressB, _to, amountB);
        balanceA = IERC20(tokenAddressA).balanceOf(address(this));
        balanceB = IERC20(tokenAddressB).balanceOf(address(this));
        _update(uint128(balanceA), uint128(balanceB));
        emit DlrMatchBurn(msg.sender, amountA, amountB, _to);
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
        Global.useTransfer(tokenAddressOut, _to, amountOut);
        uint balanceIn = IERC20(tokenAddressIn).balanceOf(address(this));
        uint balanceOut = IERC20(tokenAddressOut).balanceOf(address(this));
        uint128 amountIn = balanceIn > reserveIn
            ? uint128(balanceIn - reserveIn)
            : uint128(0);
        if ((balanceIn - amountIn) * balanceOut < reserveIn * reserveOut) {
            revert DlrLiquidity_KValueChangedLess();
        }

        uint128 amountAIn;
        uint128 amountBIn;
        uint128 amountAOut;
        uint128 amountBOut;
        uint128 balanceA;
        uint128 balanceB;
        if (isAout) {
            balanceA = uint128(balanceOut);
            balanceB = uint128(balanceIn);
            amountAIn = uint128(0);
            amountBOut = uint128(0);
            amountAOut = amountOut;
            amountBIn = amountIn;
        } else {
            balanceA = uint128(balanceIn);
            balanceB = uint128(balanceOut);
            amountAIn = amountIn;
            amountBOut = amountAOut;
            amountAOut = uint128(0);
            amountBIn = uint128(0);
        }

        emit DlrMatchSwap(
            msg.sender,
            amountAIn,
            amountBIn,
            amountAOut,
            amountBOut,
            _to
        );
    }

    function skim(address _to) external nonReentrant {
        Global.useTransfer(
            tokenAddressA,
            _to,
            uint128(IERC20(tokenAddressA).balanceOf(address(this)) - (reserveA))
        );
        Global.useTransfer(
            tokenAddressB,
            _to,
            uint128(IERC20(tokenAddressB).balanceOf(address(this)) - (reserveB))
        );
    }

    function sync() external nonReentrant {
        _update(
            uint128(IERC20(tokenAddressA).balanceOf(address(this))),
            uint128(IERC20(tokenAddressB).balanceOf(address(this)))
        );
    }

    /* Private functions */
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _mint(address _to, uint value) internal {
        totalSupply = totalSupply + value;
        balanceOf[_to] = balanceOf[_to] + value;
        emit Transfer(address(0), _to, value);
    }

    function _update(uint128 balanceA, uint128 balanceB) private {
        reserveA = balanceA;
        reserveB = balanceB;
        kLast = uint256(reserveA * reserveB);
        emit DlrMatchSync(reserveA, reserveB);
    }

    /* Getter Setter */
    function getPriceA() public view returns (uint priceA) {
        priceA = (1000 * reserveB) / reserveA;
    }

    function getPriceB() public view returns (uint priceB) {
        priceB = (1000 * reserveA) / reserveB;
    }

    /************************ERC20************************/
    string public constant name = "DLR LP Token";
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
