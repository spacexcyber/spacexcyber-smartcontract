// contracts/SpaceXCyberToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SpaceXCyberToken is ERC20, Ownable {
    using SafeMath for uint256;
    //Tax 6% when tranfer token, tranfer tax 5% to pool and 1% to mkt
    uint256 private constant _tax = 6;

    //Wallet pool send earn when tax
    address payable private _poolAddress;

    //Wallet mkt send token when tax
    address payable private _marketingAddress;

    //uniswap router use swap tax and add liq
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;

    //timestamp 1 days
    uint256 private constant _dayTimestamp = 86400;

    constructor(address poolAddress_, address mktAddress_)
        ERC20("SpaceXCyberToken", "SXC")
    {
        //setup wallet pool and mkt
        require(
            poolAddress_ != address(0) && mktAddress_ != address(0),
            "address not zero"
        );
        _poolAddress = payable(poolAddress_);

        _marketingAddress = payable(mktAddress_);

        //create swap router to swap tax
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );

        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        //mint stake
        _mint(owner(), 90_000_000_000_000_000_000_000_000);

        //mint mkt
        _mint(_marketingAddress, 10_000_000_000_000_000_000_000_000);
    }

    event SwapTax(uint256 tokensSwapped, uint256 tokensReceived);

    /**
     * override add tax to pool and mkt wallet
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (to != owner() && to != _poolAddress && to != _marketingAddress) {
            require(to != address(0), "ERC20: transfer to the zero address");
            require(
                balanceOf(_msgSender()) > amount,
                "ERC20: transfer amount exceeds balance"
            );
            uint256 taxAmount = amount.div(_tax);
            uint256 newAmount = amount.sub(taxAmount);

            require(taxAmount.add(newAmount) == amount, "Mute: math is broken");

            //swap to token to pool and mkt wallet
            _swapTokens(taxAmount);
            uint256 balance = address(this).balance;
            emit SwapTax(taxAmount, balance);
            if (balance > 0) {
                _poolAddress.transfer(balance.div(83));
                _marketingAddress.transfer(
                    balance.sub(balance.div(83))
                );
            }
            return super.transfer(to, newAmount);
        } else {
            return super.transfer(to, amount);
        }
    }

    /**
     * swap token to add pool and mkt wallet
     */
    function _swapTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), amount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * get pool address wallet
     */
    function getPoolAddress() public view returns (address) {
        return _poolAddress;
    }

    /**
     * get mkt address wallet
     */
    function getMarketingAddress() public view returns (address) {
        return _marketingAddress;
    }

    /**
     * set pool and mkt address wallet
     */
    function setConfigAddress(address poolAddress, address marketingAddress)
        public
        onlyOwner
    {
        _poolAddress = payable(poolAddress);
        _marketingAddress = payable(marketingAddress);
    }

    /**
     * add liq
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount.mul(2));

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}
