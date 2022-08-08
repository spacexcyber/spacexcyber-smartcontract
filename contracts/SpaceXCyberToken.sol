// contracts/SpaceXCyberToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract SpaceXCyberToken is ERC777 {
    constructor(address[] memory defaultOperators)
        ERC777("SpaceXCyberToken", "SNX", defaultOperators)
    {
        initToken(100_000_000_000_000_000_000_000_000);
    }

    function initToken(uint256 initialSupply) public {
        _mint(msg.sender, initialSupply, "", "");
    }
}
