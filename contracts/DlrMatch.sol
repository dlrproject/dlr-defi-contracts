// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/dex/IDlrMatch.sol";
import "./libraries/Global.sol";

contract DlrMatch is IDlrMatch, ReentrancyGuard, Ownable {
    using Global for uint256;
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
    function mint(
        address _to
    ) external nonReentrant returns (uint128 liquidity) {
        uint256 balanceA = IERC20(tokenAddressA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenAddressB).balanceOf(address(this));
        uint256 amountA = balanceA.trySub(reserveA);
        uint256 amountB = balanceB.trySub(reserveB);
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Global.sqrt(amountA.tryMul(amountB)).toUint128();
        } else {
            uint256 liquidityA = (amountA.tryMul(_totalSupply)).tryDiv(
                reserveA
            );
            uint256 liquidityB = (amountB.tryMul(_totalSupply)).tryDiv(
                reserveB
            );
            liquidity = (liquidityA > liquidityB ? liquidityB : liquidityA)
                .toUint128();
        }
        _mint(_to, liquidity);
        _update(balanceA, balanceB);
        emit DlrMatchMint(_to, amountA.toUint128(), amountB.toUint128());
    }

    function burn(
        address _to
    ) external nonReentrant returns (uint128 amountA, uint128 amountB) {
        uint256 balanceA = IERC20(tokenAddressA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenAddressB).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)]; // 刚转的 10

        amountA = (liquidity.tryMul(balanceA)).tryDiv(totalSupply).toUint128(); // using balances ensures pro-rata distribution
        amountB = (liquidity.tryMul(balanceB)).tryDiv(totalSupply).toUint128();

        _burn(address(this), liquidity);
        Global.useTransfer(tokenAddressA, _to, amountA);
        Global.useTransfer(tokenAddressB, _to, amountB);
        balanceA = IERC20(tokenAddressA).balanceOf(address(this));
        balanceB = IERC20(tokenAddressB).balanceOf(address(this));
        _update(balanceA, balanceB);
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
            uint256 reserveOut,
            address tokenAddressIn,
            uint256 reserveIn,
            uint256 amountOut
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
        uint256 balanceIn = IERC20(tokenAddressIn).balanceOf(address(this));
        uint256 balanceOut = IERC20(tokenAddressOut).balanceOf(address(this));
        uint256 amountIn = balanceIn > reserveIn
            ? balanceIn.trySub(reserveIn)
            : 0;
        if (
            (balanceIn.trySub(amountIn)).tryMul(balanceOut.tryAdd(amountOut)) <
            reserveIn.tryMul(reserveOut)
        ) {
            revert DlrLiquidity_KValueChangedLess();
        }

        uint256 amountAIn;
        uint256 amountBIn;
        uint256 amountAOut;
        uint256 amountBOut;
        uint256 balanceA;
        uint256 balanceB;
        if (isAout) {
            balanceA = balanceOut;
            balanceB = balanceIn;
            amountAIn = 0;
            amountBOut = 0;
            amountAOut = amountOut;
            amountBIn = amountIn;
        } else {
            balanceA = balanceIn;
            balanceB = balanceOut;
            amountAIn = amountIn;
            amountBOut = amountAOut;
            amountAOut = 0;
            amountBIn = 0;
        }
        _update(balanceA, balanceB);
        emit DlrMatchSwap(
            msg.sender,
            amountAIn.toUint128(),
            amountBIn.toUint128(),
            amountAOut.toUint128(),
            amountBOut.toUint128(),
            _to
        );
    }

    function skim(address _to) external nonReentrant {
        Global.useTransfer(
            tokenAddressA,
            _to,
            uint256(
                IERC20(tokenAddressA).balanceOf(address(this)).trySub(reserveA)
            )
        );
        Global.useTransfer(
            tokenAddressB,
            _to,
            uint256(
                IERC20(tokenAddressB).balanceOf(address(this)).trySub(reserveB)
            )
        );
    }

    function sync() external nonReentrant {
        _update(
            uint256(IERC20(tokenAddressA).balanceOf(address(this))),
            uint256(IERC20(tokenAddressB).balanceOf(address(this)))
        );
    }

    /* Private functions */

    function _mint(address _to, uint256 value) internal {
        totalSupply = totalSupply.tryAdd(value);
        balanceOf[_to] = balanceOf[_to].tryAdd(value);
        emit Transfer(address(0), _to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].trySub(value);
        totalSupply = totalSupply.trySub(value);
        emit Transfer(from, address(0), value);
    }

    function _update(uint256 balanceA, uint256 balanceB) private {
        reserveA = balanceA.toUint128();
        reserveB = balanceB.toUint128();
        kLast = uint256(((reserveA / 1000) * reserveB) / 1000);
        emit DlrMatchSync(reserveA, reserveB);
    }

    /* Getter Setter */
    function getPriceA() public view returns (uint128 priceA) {
        priceA = (1000 * reserveB) / reserveA;
    }

    function getPriceB() public view returns (uint128 priceB) {
        priceB = (1000 * reserveA) / reserveB;
    }

    /************************ERC20************************/
    string public constant name = "DLR LP Token";
    string public constant symbol = "DLR";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() Ownable(msg.sender) {}

    function approve(
        address spender,
        uint256 value
    ) external override nonReentrant returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(
        address to,
        uint256 value
    ) external override nonReentrant returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override nonReentrant returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].trySub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].trySub(value);
        balanceOf[to] = balanceOf[to].tryAdd(value);
        emit Transfer(from, to, value);
    }

    /************************ERC20************************/
}
