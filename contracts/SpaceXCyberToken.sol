// contracts/SpaceXCyberToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceXCyberToken is ERC20, Ownable {
    uint256 private _taxFeeOnBuy = 6;
    uint256 private _taxFeeOnSell = 6;
    address payable private _developmentAddress =
        payable(0x6985678985dE478c4E48Dcc18372e2929EfB56fc);
    address payable private _marketingAddress =
        payable(0x14fC31aFB1E6e7cb4c1E520868fC9D56587545f2);

    constructor() ERC20("SpaceXCyberToken", "SXC") {
        _initToken(100_000_000_000_000_000_000_000_000);
    }

    function _initToken(uint256 initialSupply) internal onlyOwner {
        _mint(owner(), initialSupply);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function setFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner
    {

    }

    function _tranferTax(address account, uint256 amount) internal {}
}
