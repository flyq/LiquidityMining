// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) ERC20(name_, symbol_) {
        _mint(msg.sender, totalSupply_ * 10 ** decimals());
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}