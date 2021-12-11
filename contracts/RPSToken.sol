//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RPSToken is ERC20{
    constructor(uint256 _amount) ERC20("RPSToken", "RPS"){
        _mint(msg.sender, _amount * 10 ** decimals());
    }
}