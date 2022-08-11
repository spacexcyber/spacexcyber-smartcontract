// contracts/SpaceXCyberToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {TokenTimelock} from "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";

contract SpaceXCyberToken is ERC20, Ownable {
    //Tax 5% buy
    uint256 private _taxFeeOnBuy = 6;

    //Tax 5% sell
    uint256 private _taxFeeOnSell = 6;

    //Wallet pool send earn when tax
    address payable private _poolAddress =
        payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);

    //Wallet mkt send token when tax
    address payable private _marketingAddress =
        payable(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

    constructor() ERC20("SpaceXCyberToken", "SXC") {
        //mint stake
        _mint(owner(), 90_000_000_000_000_000_000_000_000);

        //mint mkt
        _mint(_marketingAddress, 10_000_000_000_000_000_000_000_000);
    }

    /**
     * override tranfer send tax
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    /**
     * send tax
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {}

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
