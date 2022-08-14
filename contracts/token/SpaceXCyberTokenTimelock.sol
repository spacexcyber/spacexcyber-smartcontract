// contracts/token/SpaceXCyberTimeLock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract SpaceXCyberTokenTimelock is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ILO wallet address of tokens after they are released
    mapping(address => uint256) private _iloWalletAddress;

    // ICO wallet address of tokens after they are released
    mapping(address => uint256) private _icoWalletAddress;

    // team wallet address of tokens after they are released
    mapping(address => uint256) private _teamWalletAddress;

    // claimed wallet address
    mapping(address => uint256) private _claimedWalletAddress;

    // last claimed date wallet address
    mapping(address => uint256) private _lastClaimDate;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    uint256 private _max_claim_ico;
    uint256 private _max_claim_ilo;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor() {
        _releaseTime = block.timestamp + 365 days;
        _max_claim_ico = 50_000_000_000_000_000_000_000;
        _max_claim_ilo = 30_000_000_000_000_000_000_000;
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * set max supply for claim ico wallet
     */
    event SetMaxClaimIco(uint256 oldSupply, uint256 newSupply);

    function setMaxClaimIco(uint256 supply) external onlyOwner {
        emit SetMaxClaimIco(_max_claim_ico, supply);
        _max_claim_ico = supply;
    }

    /**
     * set max supply for claim ico wallet
     */
    event SetMaxClaimILo(uint256 oldSupply, uint256 newSupply);

    function setMaxClaimILo(uint256 supply) external onlyOwner {
        emit SetMaxClaimIco(_max_claim_ilo, supply);
        _max_claim_ilo = supply;
    }

    /**
     * set team wallet address for lock token
     */
    event SetToken(address oldToken, address newToken);

    function setToken(address token_) external onlyOwner {
        emit SetToken(address(_token), token_);
        _token = IERC20(token_);
    }

    /**
     * set team wallet address for lock token
     */
    event SetReleaseTime(uint256 oldTime, uint256 newTime);

    function setReleaseTime(uint256 time_) external onlyOwner {
        emit SetReleaseTime(_releaseTime, time_);
        _releaseTime = time_;
    }

    /**
     * set team wallet address for lock token
     */
    event SetTeamWalletAddress(address addr, uint256 amount);

    function setTeamWalletAddress(address addr, uint256 amount)
        external
        onlyOwner
    {
        require(
            !Address.isContract(addr) && addr != address(0) && addr != owner(),
            "addr not valid"
        );
        require(addr != owner(), "addr not valid");
        require(amount > 0, "amount must greater than zero");
        emit SetTeamWalletAddress(addr, amount);
        _teamWalletAddress[addr] = amount;
    }

    /**
     * set ico wallet address for lock token
     */
    event SetIcoWalletAddress(address addr, uint256 amount);

    function setIcoWalletAddress(address addr, uint256 amount)
        external
        onlyOwner
    {
        require(
            !Address.isContract(addr) && addr != address(0) && addr != owner(),
            "addr not valid"
        );
        require(amount > 0, "amount must greater than zero");
        require(amount <= _max_claim_ico, "amount must less than 50_000");
        emit SetIcoWalletAddress(addr, amount);
        _icoWalletAddress[addr] = amount;
    }

    /**
     * set ilo wallet address for lock token
     */
    event SetIloWalletAddress(address addr, uint256 amount);

    function setIloWalletAddress(address addr, uint256 amount)
        external
        onlyOwner
    {
        require(
            !Address.isContract(addr) && addr != address(0) && addr != owner(),
            "addr not valid"
        );
        require(amount > 0, "amount must greater than zero");
        require(amount <= _max_claim_ilo, "amount must less than 30_000");
        emit SetIloWalletAddress(addr, amount);
        _iloWalletAddress[addr] = amount;
    }

    /**
     * @dev Returns the token for IDO that will receive.
     */
    function icoWalletAmount() public view virtual returns (uint256) {
        return _icoWalletAddress[_msgSender()];
    }

    /**
     * @dev Returns the token for IDO that will receive.
     */
    function iloWalletAmount() public view returns (uint256) {
        return _iloWalletAddress[_msgSender()];
    }

    /**
     * @dev Returns the token for Team that will receive.
     */
    function teamWalletAmount() public view returns (uint256) {
        return _teamWalletAddress[_msgSender()];
    }

    /**
     * Returns the token claimed for address
     */
    function tokensClaimed(address adds) public view returns (uint256) {
        require(adds != address(0), "address not valid");
        return _claimedWalletAddress[adds];
    }

    /**
     * Returns the last date claimed for address
     */
    function lastDateClaimed(address adds) public view returns (uint256) {
        require(adds != address(0), "address not valid");
        return _lastClaimDate[adds];
    }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    event Claim(address addr, uint256 amount, uint256 timeClaim);

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function claim() external {
        require(
            block.timestamp >= releaseTime(),
            "current time is before claim time"
        );
        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "no tokens to claim");
        require(
            icoWalletAmount() > 0 ||
                iloWalletAmount() > 0 ||
                teamWalletAmount() > 0,
            "not found address claim list"
        );
        if (icoWalletAmount() > 0) {
            //Check ICO wallet claim
            _icoClaim(icoWalletAmount());
        } else if (iloWalletAmount() > 0) {
            //Check ILO wallet claim
            _iloClaim(iloWalletAmount());
        } else if (teamWalletAmount() > 0) {
            //Check Team wallet claim
            _teamClaim(teamWalletAmount());
        }
    }

    /**
     * Claim token by ILO wallet address. Will only succeed if invoked after the release and lock 12 month after release
     */
    function _icoClaim(uint256 amount) private {
        uint256 totalAmount = token().balanceOf(address(this));
        uint256 amountReceived = _claimedWalletAddress[_msgSender()];
        require(amountReceived < amount, "no tokens to claim");
        //claim 40% token after 7 days
        if (amountReceived == 0) {
            require(
                block.timestamp >= releaseTime() + 7 days,
                "no tokens to claim. claim after 7 days ILO"
            );
            uint256 amountFirstReceive = amount.mul(4).div(10);
            require(totalAmount > amountFirstReceive, "over balance");
            //tranfer token
            token().safeTransfer(_msgSender(), amountFirstReceive);

            //update claimed info
            _updateClaimInfo(amountFirstReceive);
        } else {
            require(
                block.timestamp >= _lastClaimDate[_msgSender()] + 30 days,
                "no tokens to claim. claim after 30 days"
            );
            uint256 amountReceive = amount.mul(5).div(100);
            require(totalAmount > amountReceive, "over balance");
            if (amountReceived + amountReceive > amount) {
                token().safeTransfer(_msgSender(), amount - amountReceived);
            } else {
                token().safeTransfer(_msgSender(), amountReceive);
            }
            //update claimed info
            _updateClaimInfo(amountReceive);
        }
    }

    /**
     * Claim token by ILO wallet address. Will only succeed if invoked after the release
     */
    function _iloClaim(uint256 amount) private {
        uint256 totalAmount = token().balanceOf(address(this));
        uint256 amountReceived = _claimedWalletAddress[_msgSender()];
        require(amountReceived == 0, "claimed");
        require(totalAmount > amount, "over balance");
        token().safeTransfer(_msgSender(), amount);
        //update claimed info
        _updateClaimInfo(amount);
    }

    /**
     * Claim token by Team wallet address. Will only succeed if invoked 40% after the release and lock 12 month after release
     */
    function _teamClaim(uint256 amount) private {
        uint256 totalAmount = token().balanceOf(address(this));
        uint256 amountReceived = _claimedWalletAddress[_msgSender()];
        require(amountReceived < amount, "no tokens to claim");
        require(totalAmount > amount, "over balance");
        require(
            block.timestamp >= _lastClaimDate[_msgSender()] + 30 days,
            "no tokens to claim"
        );
        uint256 amountReceive = amount.mul(5).div(100);
        require(totalAmount > amountReceive, "over balance");
        if (amountReceived + amountReceive > amount) {
            token().safeTransfer(_msgSender(), amount - amountReceived);
        } else {
            token().safeTransfer(_msgSender(), amountReceive);
        }
        //update claimed info
        _updateClaimInfo(amountReceive);
    }

    /**
     * update claim information
     */
    function _updateClaimInfo(uint256 amount) private {
        _claimedWalletAddress[_msgSender()] = amount;
        _lastClaimDate[_msgSender()] = block.timestamp;
        emit Claim(_msgSender(), amount, block.timestamp);
    }
}
