// // contracts/token/SpaceXCyberToken.sol
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// contract SpaceXCyberToken is IERC20, Ownable, IERC20Metadata {
//     using SafeMath for uint256;

//     mapping(address => uint256) private _balances;

//     mapping(address => mapping(address => uint256)) private _allowances;

//     uint256 private _totalSupply;

//     string private constant _name = "SpaceXCyberToken";
//     string private _symbol = "SXC";

//     //Tax 6% when tranfer token, tranfer tax 5% to pool and 1% to mkt
//     uint256 private constant _tax = 6;

//     //Wallet pool send earn when tax
//     address payable private _poolAddress;

//     //Wallet mkt send token when tax
//     address payable private _marketingAddress;

//     //uniswap router use swap tax and add liq
//     IUniswapV2Router02 private _uniswapV2Router;
//     address private _uniswapV2Pair;

//     //enable tax
//     bool private _enableTax;

//     //lock in swap to pool and mkt wallet
//     bool private _inSwap = false;
//     modifier lockTheSwap() {
//         _inSwap = true;
//         _;
//         _inSwap = false;
//     }

//     /**
//      * Max supply tokens
//      */
//     uint256 private _maxTotalSupply;

//     /**
//      * @dev Sets the values for {name} and {symbol}.
//      *
//      * The default value of {decimals} is 18. To select a different value for
//      * {decimals} you should overload it.
//      *
//      * All two of these values are immutable: they can only be set once during
//      * construction.
//      */
//     constructor(
//         address payable poolAddress_,
//         address payable mktAddress_,
//         address lockAddressContract_
//     ) {
//         //setup wallet pool and mkt
//         require(
//             poolAddress_ != address(0) && mktAddress_ != address(0),
//             "address not zero"
//         );
//         _poolAddress = poolAddress_;

//         _marketingAddress = mktAddress_;

//         //init max 100.000.000 tokens
//         _maxTotalSupply = 100_000_000_000_000_000_000_000_000;

//         //create swap router to swap tax
//         _uniswapV2Router = IUniswapV2Router02(
//             0xD99D1c33F9fC3444f8101754aBC46c52416550D1
//         );

//         _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
//             .createPair(address(this), _uniswapV2Router.WETH());

//         //mint to lockContract
//         require(
//             lockAddressContract_ != address(0) &&
//                 lockAddressContract_ != owner()
//         );
//         _mint(lockAddressContract_, 37_000_000_000_000_000_000_000_000);

//         //mint
//         _mint(owner(), 53_000_000_000_000_000_000_000_000);

//         //mint mkt
//         _mint(_marketingAddress, 10_000_000_000_000_000_000_000_000);

//         //disable tax
//         _enableTax = true;
//     }

//     /**
//      * @dev Returns the cap on the token's total supply.
//      */
//     function maxTotalSupply() public view virtual returns (uint256) {
//         return _maxTotalSupply;
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
//      * @dev Returns the name of the token.
//      */
//     function name() public view virtual override returns (string memory) {
//         return _name;
//     }

//     /**
//      * @dev Returns the symbol of the token, usually a shorter version of the
//      * name.
//      */
//     function symbol() public view virtual override returns (string memory) {
//         return _symbol;
//     }

//     /**
//      * @dev Returns the number of decimals used to get its user representation.
//      * For example, if `decimals` equals `2`, a balance of `505` tokens should
//      * be displayed to a user as `5.05` (`505 / 10 ** 2`).
//      *
//      * Tokens usually opt for a value of 18, imitating the relationship between
//      * Ether and Wei. This is the value {ERC20} uses, unless this function is
//      * overridden;
//      *
//      * NOTE: This information is only used for _display_ purposes: it in
//      * no way affects any of the arithmetic of the contract, including
//      * {IERC20-balanceOf} and {IERC20-transfer}.
//      */
//     function decimals() public view virtual override returns (uint8) {
//         return 18;
//     }

//     /**
//      * @dev See {IERC20-totalSupply}.
//      */
//     function totalSupply() public view virtual override returns (uint256) {
//         return _totalSupply;
//     }

//     /**
//      * @dev See {IERC20-balanceOf}.
//      */
//     function balanceOf(address account)
//         public
//         view
//         virtual
//         override
//         returns (uint256)
//     {
//         return _balances[account];
//     }

//     /**
//      * @dev See {IERC20-transfer}.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      * - the caller must have a balance of at least `amount`.
//      */
//     function transfer(address to, uint256 amount)
//         public
//         virtual
//         override
//         returns (bool)
//     {
//         address owner = _msgSender();
//         _transfer(owner, to, amount);
//         return true;
//     }

//     /**
//      * @dev See {IERC20-allowance}.
//      */
//     function allowance(address owner, address spender)
//         public
//         view
//         virtual
//         override
//         returns (uint256)
//     {
//         return _allowances[owner][spender];
//     }

//     /**
//      * @dev See {IERC20-approve}.
//      *
//      * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
//      * `transferFrom`. This is semantically equivalent to an infinite approval.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function approve(address spender, uint256 amount)
//         public
//         virtual
//         override
//         returns (bool)
//     {
//         address owner = _msgSender();
//         _approve(owner, spender, amount);
//         return true;
//     }

//     event BeforeSpendAllowance(address from, address to, uint256 amount);

//     event SpendAllowance(address from, address to, uint256 amount);

//     /**
//      * @dev See {IERC20-transferFrom}.
//      *
//      * Emits an {Approval} event indicating the updated allowance. This is not
//      * required by the EIP. See the note at the beginning of {ERC20}.
//      *
//      * NOTE: Does not update the allowance if the current allowance
//      * is the maximum `uint256`.
//      *
//      * Requirements:
//      *
//      * - `from` and `to` cannot be the zero address.
//      * - `from` must have a balance of at least `amount`.
//      * - the caller must have allowance for ``from``'s tokens of at least
//      * `amount`.
//      */
//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) public virtual override returns (bool) {
//         address spender = _msgSender();
//         emit BeforeSpendAllowance(from, spender, amount);
//         _spendAllowance(from, spender, amount);
//         emit SpendAllowance(from, spender, amount);
//         _transfer(from, to, amount);
//         return true;
//     }

//     /**
//      * @dev Atomically increases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      */
//     function increaseAllowance(address spender, uint256 addedValue)
//         public
//         virtual
//         returns (bool)
//     {
//         address owner = _msgSender();
//         _approve(owner, spender, allowance(owner, spender) + addedValue);
//         return true;
//     }

//     /**
//      * @dev Atomically decreases the allowance granted to `spender` by the caller.
//      *
//      * This is an alternative to {approve} that can be used as a mitigation for
//      * problems described in {IERC20-approve}.
//      *
//      * Emits an {Approval} event indicating the updated allowance.
//      *
//      * Requirements:
//      *
//      * - `spender` cannot be the zero address.
//      * - `spender` must have allowance for the caller of at least
//      * `subtractedValue`.
//      */
//     function decreaseAllowance(address spender, uint256 subtractedValue)
//         public
//         virtual
//         returns (bool)
//     {
//         address owner = _msgSender();
//         uint256 currentAllowance = allowance(owner, spender);
//         require(
//             currentAllowance >= subtractedValue,
//             "ERC20: decreased allowance below zero"
//         );
//         unchecked {
//             _approve(owner, spender, currentAllowance - subtractedValue);
//         }

//         return true;
//     }

//     /**
//      * @dev Moves `amount` of tokens from `from` to `to`.
//      *
//      * This internal function is equivalent to {transfer}, and can be used to
//      * e.g. implement automatic token fees, slashing mechanisms, etc.
//      *
//      * Emits a {Transfer} event.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `to` cannot be the zero address.
//      * - `from` must have a balance of at least `amount`.
//      */
//     function _transfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal virtual {
//         require(from != address(0), "ERC20: transfer from the zero address");
//         require(to != address(0), "ERC20: transfer to the zero address");
//         //amount to tranfer
//         uint256 fromBalance = _balances[from];
//         require(
//             fromBalance >= amount,
//             "ERC20: transfer amount exceeds balance"
//         );
//         unchecked {
//             _balances[from] = fromBalance - amount;
//         }
//         _beforeTokenTransfer(from, to, amount);

//         uint256 tranferAmount = amount;
//         if (from != owner() && to != owner()) {
//             //swap token when hodler buy
//             if (!_inSwap && _enableTax && from != _uniswapV2Pair) {
//                 _swapTaxAddPoolAndMarketting();
//             }

//             //get tax
//             if (
//                 from != address(this) &&
//                 to != address(this) &&
//                 from != _poolAddress &&
//                 to != _poolAddress &&
//                 from != _marketingAddress &&
//                 to != _marketingAddress &&
//                 ((from == _uniswapV2Pair && to != address(_uniswapV2Router)) ||
//                     (to == _uniswapV2Pair && from != address(_uniswapV2Router)))
//             ) {
//                 uint256 taxAmount = amount.mul(_tax).div(100);
//                 uint256 newAmount = amount.sub(taxAmount);
//                 require(
//                     taxAmount.add(newAmount) == amount && taxAmount > 0,
//                     "Mute: math is broken"
//                 );
//                 //tranfer
//                 _balances[address(this)] += taxAmount;
//                 emit Transfer(from, address(this), taxAmount);
//                 tranferAmount = newAmount;
//             }
//         }
//         _balances[to] += tranferAmount;

//         emit Transfer(from, to, tranferAmount);

//         _afterTokenTransfer(from, to, amount);
//     }

//     /**
//      * swap tax token to add pool and marketting fee
//      */
//     function _swapTaxAddPoolAndMarketting() private {
//         uint256 contractBalance = balanceOf(address(this));
//         if (contractBalance > 0) {
//             //swap to token to pool and mkt wallet
//             _swapTokens(contractBalance);
//             uint256 balance = address(this).balance;
//             //emit event swap
//             emit SwapTax(contractBalance, balance);
//             if (balance > 0) {
//                 uint256 rateToPool = 80;
//                 _poolAddress.transfer(balance.mul(rateToPool).div(100));
//                 _marketingAddress.transfer(
//                     balance.sub(balance.mul(rateToPool).div(100))
//                 );
//             }
//         }
//     }

//     /** @dev Creates `amount` tokens and assigns them to `account`, increasing
//      * the total supply.
//      *
//      * Emits a {Transfer} event with `from` set to the zero address.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      */
//     function _mint(address account, uint256 amount) internal virtual {
//         require(
//             totalSupply() + amount <= maxTotalSupply(),
//             "ERC20Capped: cap exceeded"
//         );

//         require(account != address(0), "ERC20: mint to the zero address");

//         _beforeTokenTransfer(address(0), account, amount);

//         _totalSupply += amount;
//         _balances[account] += amount;
//         emit Transfer(address(0), account, amount);

//         _afterTokenTransfer(address(0), account, amount);
//     }

//     /**
//      * @dev Destroys `amount` tokens from `account`, reducing the
//      * total supply.
//      *
//      * Emits a {Transfer} event with `to` set to the zero address.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      * - `account` must have at least `amount` tokens.
//      */
//     function _burn(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _beforeTokenTransfer(account, address(0), amount);

//         uint256 accountBalance = _balances[account];
//         require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
//         unchecked {
//             _balances[account] = accountBalance - amount;
//         }
//         _totalSupply -= amount;

//         emit Transfer(account, address(0), amount);

//         _afterTokenTransfer(account, address(0), amount);
//     }

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
//      *
//      * This internal function is equivalent to `approve`, and can be used to
//      * e.g. set automatic allowances for certain subsystems, etc.
//      *
//      * Emits an {Approval} event.
//      *
//      * Requirements:
//      *
//      * - `owner` cannot be the zero address.
//      * - `spender` cannot be the zero address.
//      */
//     function _approve(
//         address owner,
//         address spender,
//         uint256 amount
//     ) internal virtual {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//     /**
//      * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
//      *
//      * Does not update the allowance amount in case of infinite allowance.
//      * Revert if not enough allowance is available.
//      *
//      * Might emit an {Approval} event.
//      */
//     function _spendAllowance(
//         address owner,
//         address spender,
//         uint256 amount
//     ) internal virtual {
//         uint256 currentAllowance = allowance(owner, spender);
//         if (currentAllowance != type(uint256).max) {
//             require(
//                 currentAllowance >= amount,
//                 "ERC20: insufficient allowance"
//             );
//             unchecked {
//                 _approve(owner, spender, currentAllowance - amount);
//             }
//         }
//     }

//     /**
//      * @dev Hook that is called before any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * will be transferred to `to`.
//      * - when `from` is zero, `amount` tokens will be minted for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal virtual {}

//     /**
//      * @dev Hook that is called after any transfer of tokens. This includes
//      * minting and burning.
//      *
//      * Calling conditions:
//      *
//      * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
//      * has been transferred to `to`.
//      * - when `from` is zero, `amount` tokens have been minted for `to`.
//      * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
//      * - `from` and `to` are never both zero.
//      *
//      * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
//      */
//     function _afterTokenTransfer(
//         address from,
//         address to,
//         uint256 amount
//     ) internal virtual {}

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
//         _approve(address(this), address(_uniswapV2Router), tokenAmount.mul(2));

//         // add the liquidity
//         _uniswapV2Router.addLiquidityETH{value: ethAmount}(
//             address(this),
//             tokenAmount,
//             0, // slippage is unavoidable
//             0, // slippage is unavoidable
//             owner(),
//             block.timestamp
//         );
//     }

//     /**
//      * Log when swap tax to pool and mkt wallet
//      */
//     event SwapTax(uint256 tokensSwapped, uint256 tokensReceived);

//     /**
//      * swap token to add pool and mkt wallet
//      */
//     function _swapTokens(uint256 amount) private lockTheSwap {
//         address[] memory path = new address[](2);
//         path[0] = address(this);
//         path[1] = _uniswapV2Router.WETH();
//         _approve(address(this), address(_uniswapV2Router), amount);
//         _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//             amount,
//             0,
//             path,
//             address(this),
//             block.timestamp
//         );
//     }
// }
