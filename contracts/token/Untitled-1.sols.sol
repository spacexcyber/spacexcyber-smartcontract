// // contracts/token/SpaceXCyberToken.sol
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// contract SpaceXCyberToken is ERC20, Ownable {
//     using SafeMath for uint256;
//     //Tax 6% when tranfer token, tranfer tax 5% to pool and 1% to mkt
//     uint256 private constant _tax = 6;

//     //Wallet pool send earn when tax
//     address payable private _poolAddress;

//     //Wallet mkt send token when tax
//     address payable private _marketingAddress;

//     //uniswap router use swap tax and add liq
//     IUniswapV2Router02 public uniswapV2Router;
//     address public uniswapV2Pair;

//     //timestamp 1 days
//     uint256 private constant _dayTimestamp = 86400;

//     //enable tax
//     bool private _enableTax;

//     //lock in swap to pool and mkt wallet
//     bool public inSwap = false;
//     modifier lockTheSwap() {
//         inSwap = true;
//         _;
//         inSwap = false;
//     }

//     constructor(address payable poolAddress_, address payable mktAddress_)
//         ERC20("SpaceXCyberToken", "SXC")
//     {
//         //setup wallet pool and mkt
//         require(
//             poolAddress_ != address(0) && mktAddress_ != address(0),
//             "address not zero"
//         );
//         _poolAddress = poolAddress_;

//         _marketingAddress = mktAddress_;

//         //create swap router to swap tax
//         IUniswapV2Router02 uniswapV2Router_ = IUniswapV2Router02(
//             0xD99D1c33F9fC3444f8101754aBC46c52416550D1
//         );

//         uniswapV2Pair = IUniswapV2Factory(uniswapV2Router_.factory())
//             .createPair(address(this), uniswapV2Router_.WETH());
//         uniswapV2Router = uniswapV2Router_;

//         //mint stake
//         _mint(owner(), 90_000_000_000_000_000_000_000_000);

//         //mint mkt
//         _mint(_marketingAddress, 10_000_000_000_000_000_000_000_000);

//         //disable tax
//         _enableTax = true;
//     }

//     /**
//      * Log when swap tax to pool and mkt wallet
//      */
//     event SwapTax(uint256 tokensSwapped, uint256 tokensReceived);

//     /**
//      * override add tax to pool and mkt wallet
//      */
//     function _transfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal override {
//         //amount to tranfer
//         uint256 tranferAmount = amount;
//         if (
//             from != owner() &&
//             to != owner() &&
//             from != address(this) &&
//             to != address(this)
//         ) {
//             uint256 contractBalance = balanceOf(address(this));
//             if (
//                 !inSwap &&
//                 _enableTax &&
//                 contractBalance > 0 &&
//                 from != uniswapV2Pair
//             ) {
//                 //swap to token to pool and mkt wallet
//                 _swapTokens(contractBalance);
//                 uint256 balance = address(this).balance;
//                 //emit event swap
//                 emit SwapTax(contractBalance, balance);
//                 if (balance > 0) {
//                     uint256 rateToPool = 80;
//                     _poolAddress.transfer(balance.mul(rateToPool).div(100));
//                     _marketingAddress.transfer(
//                         balance.sub(balance.mul(rateToPool).div(100))
//                     );
//                 }
//             }

//             //get tax
//             if (
//                 from != _poolAddress &&
//                 from != _marketingAddress &&
//                 to != _poolAddress &&
//                 to != _marketingAddress &&
//                 ((from == uniswapV2Pair && to != address(uniswapV2Router)) ||
//                     (to == uniswapV2Pair && from != address(uniswapV2Router)))
//             ) {
//                 uint256 taxAmount = amount.mul(_tax).div(100);
//                 uint256 newAmount = amount.sub(taxAmount);
//                 require(
//                     taxAmount.add(newAmount) == amount && taxAmount > 0,
//                     "Mute: math is broken"
//                 );
//                 //tranfer
//                 super._transfer(from, address(this), taxAmount);
//                 tranferAmount = amount.sub(taxAmount);
//             }
//         }

//         super._transfer(from, to, tranferAmount);
//     }

//     /**
//      * swap token to add pool and mkt wallet
//      */
//     function _swapTokens(uint256 amount) private lockTheSwap {
//         address[] memory path = new address[](2);
//         path[0] = address(this);
//         path[1] = uniswapV2Router.WETH();
//         _approve(address(this), address(uniswapV2Router), amount);
//         uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//             amount,
//             0,
//             path,
//             address(this),
//             block.timestamp
//         );
//     }

//     /**
//      * get pool address wallet
//      */
//     function poolAddress() external view returns (address) {
//         return _poolAddress;
//     }

//     /**
//      * get mkt address wallet
//      */
//     function marketingAddress() external view returns (address) {
//         return _marketingAddress;
//     }

//     /**
//      * Log when set pool address
//      */
//     event SetPoolAddress(address oldAddress, address newAddress);

//     /**
//      * set pool address wallet
//      */
//     function setPoolAddress(address payable poolAddress_) external onlyOwner {
//         emit SetPoolAddress(_poolAddress, poolAddress_);
//         _poolAddress = poolAddress_;
//     }

//     /**
//      * Log when set Marketing address
//      */
//     event SetMarketingAddress(address oldAddress, address newAddress);

//     /**
//      * set pool and mkt address wallet
//      */
//     function setMarketingAddress(address payable marketingAddress_)
//         external
//         onlyOwner
//     {
//         emit SetMarketingAddress(_marketingAddress, marketingAddress_);
//         _marketingAddress = marketingAddress_;
//     }

//     event EnableTax(bool oldStatus, bool newStatus);

//     /**
//      * enable tax to pool and mkt
//      */
//     function enableTax(bool enableTax_) external onlyOwner {
//         emit EnableTax(_enableTax, enableTax_);
//         _enableTax = enableTax_;
//     }

//     /**
//      * add liq
//      */
//     function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
//         // approve token transfer to cover all possible scenarios
//         _approve(address(this), address(uniswapV2Router), tokenAmount.mul(2));

//         // add the liquidity
//         uniswapV2Router.addLiquidityETH{value: ethAmount}(
//             address(this),
//             tokenAmount,
//             0, // slippage is unavoidable
//             0, // slippage is unavoidable
//             owner(),
//             block.timestamp
//         );
//     }
// }
