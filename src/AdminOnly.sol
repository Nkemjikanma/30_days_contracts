// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AdminOnly is Ownable {
    error AdminOnly__NotAuthorized();
    error AdminOnly__InvalidTreasureAmount();
    error AdminOnly__AlreadyWithdrawn();
    error AdminOnly__InvalidUser();
    error AdminOnly__WithdrawFailed();
    error AdminOnly__InvalidAddress();

    struct TreasuryChest {
        address owner;
        string name;
        uint256 totalTreasure;
        mapping(address => uint256) withdrawAllowance;
        mapping(address => bool) hasWithdrawn;
    }

    TreasuryChest public treasureChest;

    // if multiple chests
    // mapping(uint256 => TreasureChest) public treasureChests;
    // uint256 public treasureChestCount;

    address public treasuryOwner;

    modifier onlyTreasuryOwner(address _sender) {
        if (_sender != treasureChest.owner) {
            revert AdminOnly__NotAuthorized();
        }
        _;
    }

    event TreasureAdded(uint256 amount);
    event WithdrawalApproved(uint256 amount, address indexed user);
    event WithdrawStatusReset(address indexed user);
    event OwnershipTransfered(address indexed oldOwner, address indexed newOwner);

    constructor(address _owner) Ownable(_owner) {
        treasuryOwner = _owner;

        treasureChest.owner = treasuryOwner;
        treasureChest.name = "The Stash";
        treasureChest.totalTreasure = 0;
    }

    function addTreasure(uint256 _treasureAmount, address _sender) external onlyTreasuryOwner(_sender) {
        treasureChest.totalTreasure += _treasureAmount;

        emit TreasureAdded(_treasureAmount);
    }

    function approveWithdrawal(address _user, uint256 _amount, address _owner) external onlyTreasuryOwner(_owner) {
        if (_amount <= 0) {
            revert AdminOnly__InvalidTreasureAmount();
        }

        treasureChest.withdrawAllowance[_user] += _amount;

        emit WithdrawalApproved(_amount, _user);
    }

    function withdrawTreasure(uint256 _amount, address _user) external {
        if (treasureChest.withdrawAllowance[_user] <= 0) {
            revert AdminOnly__InvalidUser();
        }
        if (treasureChest.hasWithdrawn[_user] == false) {
            revert AdminOnly__AlreadyWithdrawn();
        }
        if (_amount > treasureChest.totalTreasure) {
            revert AdminOnly__InvalidTreasureAmount();
        }

        treasureChest.totalTreasure -= _amount;
        treasureChest.hasWithdrawn[_user] = true;

        (bool success,) = _user.call{value: _amount}("");

        if (success != true) {
            revert AdminOnly__WithdrawFailed();
        }
    }

    function resetWithdrawStatus(address _owner, address _user) external onlyTreasuryOwner(_owner) {
        treasureChest.hasWithdrawn[_user] = false;

        emit WithdrawStatusReset(_user);
    }

    function transferOwnership(address _owner, address _newOwner) external onlyTreasuryOwner(_owner) {
        if (_newOwner == address(0)) {
            revert AdminOnly__InvalidAddress();
        }

        address oldOwner = treasureChest.owner;
        treasureChest.owner = _newOwner;

        emit OwnershipTransfered(oldOwner, _newOwner);
    }

    // VIEWS
    function getTotalTreasure() external view returns (uint256) {
        return treasureChest.totalTreasure;
    }

    function getWithdrawalAllowance(address _user) external view returns (uint256) {
        return treasureChest.withdrawAllowance[_user];
    }

    function hasUserWithdrawn(address _user) external view returns (bool) {
        return treasureChest.hasWithdrawn[_user];
    }

    function getOwner() external view returns (address) {
        return treasureChest.owner;
    }

    // Required to receive ETH
    // receive() external payable {
    //     treasureChest.totalTreasure += msg.value;
    //     emit TreasureAdded(msg.value);
    // }
}
