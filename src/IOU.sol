//SPDX-License-identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract IOU is Ownable {
    struct Debt {
        address creditor; // Who the debt is owed to
        uint256 amount;
        string description;
        uint256 timestamp;
        bool isSettled;
    }
    struct Friend {
        uint256 totalDeposited;
        uint256 availableBalance;
        uint256 totalOwed;
        uint256 totalOwedToUser;
        // debts owed to user
        mapping(address => Debt[]) debtsOwedToMe;
    }

    mapping(address => Friend) public friendGroup;

    // debts - Debtor to Creditor to list of Debts
    mapping(address => mapping(address => Debt[])) public debtsOwed;
    mapping(address => mapping(address => Debt[])) public debtsOwedToMe;

    // Track all members of the group
    address[] public members;
    mapping(address => bool) public isMember;

    constructor(address _initialOwner) Ownable(_initialOwner) {}
}
