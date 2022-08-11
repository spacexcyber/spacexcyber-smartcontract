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
    uint256 private constant _taxPool = 5;

    uint256 private constant _taxMarketing = 1;

    //Wallet pool send earn when tax
    address payable private _poolAddress;

    //Wallet mkt send token when tax
    address payable private _marketingAddress;
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;

    constructor(
        address poolAddress_,
        address mktAddress_
    ) ERC20("SpaceXCyberToken", "SXC") {
        //setup wallet pool and mkt
        require(
            poolAddress_ != address(0) && mktAddress_ != address(0),
            "address not zero"
        );
        _poolAddress = payable(poolAddress_);

        _marketingAddress = payable(mktAddress_);

        //create swap router to swap tax
        _uniswapV2Router = IUniswapV2Router02(0x03E6c12eF405AC3F642B9184eDed8E1322de1a9e);

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        //mint stake
        _mint(owner(), 90_000_000_000_000_000_000_000_000);

        //mint mkt
        _mint(mktAddress_, 10_000_000_000_000_000_000_000_000);
    }

    /**
     * tranfer tax 5% to pool and 1% to marketting
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _tranferTax(from, to, amount);
    }

    /**
     * tranfer tax 5% to pool and 1% to marketting
     */
    function _tranferTax(
        address from,
        address to,
        uint256 amount
    ) private {
        if (
            from != owner() &&
            to != owner() &&
            from != _uniswapV2Pair &&
            from != _poolAddress &&
            from != _marketingAddress &&
            to != _poolAddress &&
            to != _marketingAddress
        ) {
            uint256 taxPoolAmount = amount.mul(_taxPool).div(100);
            uint256 taxMktAmount = amount.mul(_taxMarketing).div(100);
            if (taxPoolAmount > 0) {
                amount -= taxPoolAmount;
            }
            if (taxPoolAmount > 0) {
                amount -= taxMktAmount;
            }
            //swap to token to pool and mkt wallet
            _swapTokens(taxPoolAmount.add(taxMktAmount));
            uint256 balance = address(this).balance;
            _poolAddress.transfer(balance.mul(80).div(100));
            _marketingAddress.transfer(balance.mul(20).div(100));
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

    function _tranferTax(address account, uint256 amount) internal {}
}
