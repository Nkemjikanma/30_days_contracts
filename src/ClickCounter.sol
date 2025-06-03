// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ClickCounter is Ownable {
    mapping(address => uint256) public numbers;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function increment(address account) public {
        numbers[account] = numbers[account] + 1;
    }

    function setNumber(uint256 _number) public {
        numbers[msg.sender] = _number;
    }

    function getNumber(address sender) public view returns (uint256) {
        return numbers[sender];
    }
}
