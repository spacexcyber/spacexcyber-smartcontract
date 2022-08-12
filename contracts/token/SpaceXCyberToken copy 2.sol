// // contracts/SpaceXCyberToken.sol
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// contract SpaceXCyberToken is IERC20, Ownable {
//     using SafeMath for uint256;
//     using Address for address;

//     mapping (address => mapping (address => uint256)) private _allowances;
//     mapping (address => uint256) private _balances;

//     string private _name = "SpaceXCyberToken";
//     string private _symbol = "SXC";
//     uint8 private _decimals = 18;
//     uint256 private _totalSupply = 100000000e18;
            
//     uint16 public TAX_FRACTION = 20;
//     uint16 public LP_FRACTION = 20;
//     address public taxReceiveAddress;

//     bool public isTaxEnabled;
//     mapping(address => bool) public nonTaxedAddresses;
    
//     IUniswapV2Router02 public uniswapV2Router;
//     address public uniswapV2Pair;
    
//     event SwapAndLiquify(
//       uint256 tokensSwapped,
//       uint256 ethReceived,
//       uint256 tokensIntoLiqudity
//     );

//     constructor () public {
//         isTaxEnabled = true;
//         taxReceiveAddress =  msg.sender;
//         _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
//         emit Transfer(address(0), msg.sender, _totalSupply);
        
//         // Initialize route to pancakeswap
//         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    
//         uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
//           .createPair(address(this), _uniswapV2Router.WETH());
    
//         // set the rest of the contract variables
//         uniswapV2Router = _uniswapV2Router;
//     }


//     function name() public view returns (string memory) {
//         return _name;
//     }

//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     function decimals() public view returns (uint8) {
//         return _decimals;
//     }

//     function totalSupply() public view override returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address account) public view override returns (uint256) {
//         return _balances[account];
//     }


//     function allowance(address owner, address spender) public view override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     function approve(address spender, uint256 amount) public override returns (bool) {
//         _approve(_msgSender(), spender, amount);
//         return true;
//     }

//     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
//         _transfer(sender, recipient, amount);
//         _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
//         return true;
//     }

//     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
//         return true;
//     }

//     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
//         _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
//         return true;
//     }


//     function _approve(address owner, address spender, uint256 amount) internal {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     function transfer(address recipient, uint256 amount) external override returns (bool) {
//         _transfer(_msgSender(), recipient, amount);
//         return true;
//     }

//     // 100 divided by TAX_FRACTION is percentage
//     function setTaxFraction(uint16 _TAX_FRACTION) external onlyOwner {
//         TAX_FRACTION = _TAX_FRACTION;
//     }  
    
//     // 100 divided by LP_FRACTION is percentage
//     function setLpFraction(uint16 _LP_FRACTION) external onlyOwner {
//         LP_FRACTION = _LP_FRACTION;
//     }  

//     function _transfer(address sender, address recipient, uint256 amount) internal {
//         require(sender != address(0), "Mute: transfer from the zero address");
//         require(recipient != address(0), "Mute: transfer to the zero address");

//         if (nonTaxedAddresses[sender] == true || TAX_FRACTION == 0 || isTaxEnabled == false){
//           _balances[sender] = _balances[sender].sub(amount, "Mute: transfer amount exceeds balance");
//           _balances[recipient] = _balances[recipient].add(amount);

//           emit Transfer(sender, recipient, amount);
//           return;
//         }

//         uint256 feeAmount = amount.div(TAX_FRACTION);
//         uint256 lpAmount = amount.div(LP_FRACTION);
//         uint256 newAmount = amount.sub(feeAmount).sub(lpAmount);

//         require(amount == newAmount.add(feeAmount).add(lpAmount), "Mute: math is broken");

//         _balances[sender] = _balances[sender].sub(amount, "Mute: transfer amount exceeds balance");

//         _balances[recipient] = _balances[recipient].add(newAmount);

//         _balances[taxReceiveAddress] = _balances[taxReceiveAddress].add(feeAmount);
//         _balances[address(this)] = _balances[address(this)].add(lpAmount);


//         emit Transfer(sender, recipient, newAmount);
//         emit Transfer(sender, taxReceiveAddress, feeAmount);
//         emit Transfer(sender, address(this), lpAmount);

//     }
    
//     function swapTokensForBnb(uint256 tokenAmount) internal {
//       // generate the uniswap pair path of token -> weth
//       address[] memory path = new address[](2);
//       path[0] = address(this);
//       path[1] = uniswapV2Router.WETH();
        
//       _approve(address(this), address(uniswapV2Router), tokenAmount);
    
//       // make the swap
//       uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//         tokenAmount,
//         0, // accept any amount of ETH
//         path,
//         address(this),
//         block.timestamp
//       );
//     }

//   function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
//     // approve token transfer to cover all possible scenarios
//     _approve(address(this), address(uniswapV2Router), tokenAmount.mul(2));

//     // add the liquidity
//     uniswapV2Router.addLiquidityETH{value: ethAmount}(
//         address(this),
//         tokenAmount,
//         0, // slippage is unavoidable
//         0, // slippage is unavoidable
//         owner(),
//         block.timestamp
//     );
//   }
  

//   function swapAndLiquify() external onlyOwner {
//     // split the contract balance into halves
//     uint256 contractTokenBalance = balanceOf(address(this));
//     uint256 half = contractTokenBalance.div(2);
//     uint256 otherHalf = contractTokenBalance.sub(half);

//     // capture the contract's current BNB balance.
//     // this is so that we can capture exactly the amount of BNB that the
//     // swap creates, and not make the liquidity event include any BNB that
//     // has been manually sent to the contract
//     uint256 initialBalance = address(this).balance;

//     // swap tokens for ETH
//     swapTokensForBnb(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

//     // how much ETH did we just swap into?
//     uint256 newBalance = address(this).balance.sub(initialBalance);

//     // add liquidity to uniswap
//     addLiquidity(otherHalf, newBalance);
    
//     emit SwapAndLiquify(half, newBalance, otherHalf);
//   }
    
//   function setTaxReceiveAddress(address _taxReceiveAddress) external onlyOwner {
//     taxReceiveAddress = _taxReceiveAddress;
//   }

//   function setIsTaxEnabled (bool _isTaxEnabled) external onlyOwner {
//     isTaxEnabled = _isTaxEnabled;
//   }
// }
