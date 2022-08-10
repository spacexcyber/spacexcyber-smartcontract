// contracts/token/SpaceXCyberTimeLock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceXCyberTokenTimelock is Ownable {
    using SafeERC20 for IERC20;

    //increment id
    uint256 private counter;

    // ILO wallet address of tokens after they are released
    mapping(uint256 => mapping(address => uint256)) private _iloWalletAddress;

    // ICO wallet address of tokens after they are released
    mapping(uint256 => mapping(address => uint256)) private _icoWalletAddress;

    // team wallet address of tokens after they are released
    mapping(uint256 => mapping(address => uint256)) private _teamWalletAddress;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(IERC20 token_, uint256 releaseTime_) {
        require(
            releaseTime_ > block.timestamp,
            "TokenTimelock: release time is before current time"
        );
        _token = token_;
        _releaseTime = releaseTime_;
    }

    /**
     * @dev Returns the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * set team wallet address for lock token
     */
    function setTeamWalletAddress(address addr, uint256 amount) public {
        uint256 id = _getId();
        _teamWalletAddress[id][addr] = amount;
    }

    /**
     * set ico wallet address for lock token
     */
    function setIcoWalletAddress(address addr, uint256 amount)
        public
        onlyOwner
    {
        uint256 id = _getId();
        _icoWalletAddress[id][addr] = amount;
    }

    /**
     * set ilo wallet address for lock token
     */
    function setIloWalletAddress(address addr, uint256 amount)
        public
        onlyOwner
    {
        uint256 id = _getId();
        _iloWalletAddress[id][addr] = amount;
    }

    // /**
    //  * @dev Returns the IDO Wallet Address that will receive the tokens.
    //  */
    // function icoWalletAddress() public view virtual returns (address[] memory) {
    //     return _icoWalletAddress;
    // }

    // /**
    //  * @dev Returns the Team Wallet Address that will receive the tokens.
    //  */
    // function teamWalletAddress() public view virtual returns (address) {
    //     return _teamWalletAddress;
    // }

    /**
     * @dev Returns the time when the tokens are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function claim() public {
        require(
            block.timestamp >= releaseTime(),
            "current time is before claim time"
        );

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "no tokens to claim");

        // if (_exists(_icoWalletAddress, _msgSender())) {
        //     //Check ICO wallet claim
        //     _icoClaim(amount);
        // } else if (_exists(_iloWalletAddress, _msgSender())) {
        //     //Check ILO wallet claim
        //     _iloClaim();
        // } else if (_teamWalletAddress == _msgSender()) {
        //     //Check Team wallet claim
        //     _teamClaim();
        // }
    }

    /**
     * Claim token by ILO wallet address. Will only succeed if invoked 40% after the release and lock 12 month after release
     */
    function _icoClaim(uint256 amount) internal {
        //claim 40% token after 7 days
        if (block.timestamp >= releaseTime() + 7 days) {}
        require(
            block.timestamp >= releaseTime() + 7 days,
            "current time is before ico claim time"
        );

        token().safeTransfer(_msgSender(), 100_000_000);
    }

    /**
     * Claim token by ILO wallet address. Will only succeed if invoked 40% after the release and lock 12 month after release
     */
    function _iloClaim() internal {}

    /**
     * Claim token by Team wallet address. Will only succeed if invoked 40% after the release and lock 12 month after release
     */
    function _teamClaim() internal {}

    /**
     * @dev Returns whether `address` exists.
     */
    function _exists(address[] memory addrs, address addr)
        internal
        view
        virtual
        returns (bool)
    {
        require(addrs.length > 0, "address[] not empty");
        require(addr != address(0), "address zero is not a valid");
        for (uint256 i = 0; i < addrs.length; ++i) {
            if (addrs[i] == addr) {
                return true;
            }
        }
        return false;
    }

    /**
     * get incement id
     */
    function _getId() internal returns (uint256) {
        return counter++;
    }
}
