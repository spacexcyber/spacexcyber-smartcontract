// contracts/token/SpaceXCyberToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SpaceXCyberToken is ERC20, Ownable {
    using SafeMath for uint256;
    /**
     * @dev Tax 6% when tranfer token, tranfer tax 5% to pool and 1% to mkt
     */
    uint256 private constant _tax = 6;

    /**
     * @dev Wallet pool send earn when tax
     */
    address payable private _poolAddress;

    /**
     * @dev Wallet mkt send token when tax
     */
    address payable private _marketingAddress;

    /**
     * @dev uniswap router use swap tax and add liq
     */
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    /**
     * @dev enable tax
     */
    bool private _enableSwapTax;

    /**
     * @dev lock in swap to pool and mkt wallet
     */
    bool private _inSwap;
    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /**
     * @dev Max supply tokens
     */
    uint256 private _maxTotalSupply;

    /**
     * @dev new address contract which upgrade contract
     */
    address private _newAddressContract;

    constructor() ERC20("SpaceXCyberToken", "SXC") {
        //max total supply
        _maxTotalSupply = 100 * 10**6 * 10**18;

        //init total supply
        _mint(owner(), 100 * 10**6 * 10**18);

        //disable tax
        _enableSwapTax = false;

        //lock swap ?
        _inSwap = false;
    }

    /**
     * @dev get pool address wallet
     */
    function poolAddress() external view returns (address) {
        return _poolAddress;
    }

    /**
     * @dev get mkt address wallet
     */
    function marketingAddress() external view returns (address) {
        return _marketingAddress;
    }

    /**
     * @dev init swap which swap tax to pool and mkt wallet
     */
    event InitUniswap(address address_);

    function initUniswap(address address_) external onlyOwner {
        //create swap router to swap tax
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(address_);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        emit InitUniswap(address_);
    }

    /**
     * @dev Log when swap tax to pool and mkt wallet
     */
    event SwapTax(uint256 tokensSwapped, uint256 tokensReceived);

    /**
     * @dev override add tax to pool and mkt wallet
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //amount to tranfer
        uint256 tranferAmount = amount;
        if (from != owner() && to != owner()) {
            uint256 contractBalance = balanceOf(address(this));
            if (
                !_inSwap &&
                from != uniswapV2Pair &&
                _enableSwapTax &&
                contractBalance > 0
            ) {
                //swap to token to pool and mkt wallet
                _swapTokens(contractBalance);
                uint256 balance = address(this).balance;
                //emit event swap
                emit SwapTax(contractBalance, balance);
                if (balance > 0) {
                    uint256 rateToPool = 80;
                    _poolAddress.transfer(balance.mul(rateToPool).div(100));
                    _marketingAddress.transfer(
                        balance.sub(balance.mul(rateToPool).div(100))
                    );
                }
            }

            //get tax
            if (
                from != address(this) &&
                to != address(this) &&
                from != _poolAddress &&
                to != _poolAddress &&
                from != _marketingAddress &&
                to != _marketingAddress &&
                ((from == uniswapV2Pair && to != address(uniswapV2Router)) ||
                    (to == uniswapV2Pair && from != address(uniswapV2Router)))
            ) {
                uint256 taxAmount = amount.mul(_tax).div(100);
                uint256 newAmount = amount.sub(taxAmount);
                require(
                    taxAmount.add(newAmount) == amount && taxAmount > 0,
                    "Mute: math is broken"
                );
                //tranfer
                super._transfer(from, address(this), taxAmount);
                tranferAmount = newAmount;
            }
        }

        super._transfer(from, to, tranferAmount);
    }

    /**
     * @dev swap token to add pool and mkt wallet
     */
    function _swapTokens(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Log when set pool address
     */
    event SetPoolAddress(address oldAddress, address newAddress);

    /**
     * @dev set pool address wallet
     */
    function setPoolAddress(address payable poolAddress_) external onlyOwner {
        emit SetPoolAddress(_poolAddress, poolAddress_);
        _poolAddress = poolAddress_;
    }

    /**
     * @dev Log when set Marketing address
     */
    event SetMarketingAddress(address oldAddress, address newAddress);

    /**
     * @dev set pool and mkt address wallet
     */
    function setMarketingAddress(address payable marketingAddress_)
        external
        onlyOwner
    {
        emit SetMarketingAddress(_marketingAddress, marketingAddress_);
        _marketingAddress = marketingAddress_;
    }

    event EnableTax(bool oldStatus, bool newStatus);

    /**
     * @dev enable tax to pool and mkt
     */
    function enableTax(bool enableTax_) external onlyOwner {
        emit EnableTax(_enableSwapTax, enableTax_);
        _enableSwapTax = enableTax_;
    }

    /**
     * @dev add liq
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount.mul(2));

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    /**
     * @dev Swap manual tax to pool and mkt
     */
    event ManualSwapTax(uint256 tokenBalance, uint256 balance);

    function manualSwapTax() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "manualSwapTax: balance equal zero");
        //swap to token to pool and mkt wallet
        _swapTokens(contractBalance);
        uint256 balance = address(this).balance;
        //emit event swap
        emit SwapTax(contractBalance, balance);
        if (balance > 0) {
            uint256 rateToPool = 80;
            _poolAddress.transfer(balance.mul(rateToPool).div(100));
            _marketingAddress.transfer(
                balance.sub(balance.mul(rateToPool).div(100))
            );
        }
        emit ManualSwapTax(contractBalance, balance);
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply() + amount <= _maxTotalSupply,
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }
}
