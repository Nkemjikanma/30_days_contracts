// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EtherPiggy is Ownable {
    error PiggyBank__NotValidAccount();
    error PiggBank__MemberAlreadyExists();
    error EtherPiggy__InvalidAmount();
    error EtherPiggy__WithdrawalFailed();

    address public bankManager;

    struct AccountDetail {
        address walletAddress;
        uint256 totalBalance;
        uint256 createdAt;
        // date to amount mapping
        mapping(uint256 => uint256) deposits;
        bool exists;
    }

    mapping(address => AccountDetail) public accounts;
    address[] private accountNumbersList;

    // onlyAccountHolders
    modifier onlyAccountHolder(address _accountNumber) {
        if (_accountNumber == address(0)) {
            revert PiggyBank__NotValidAccount();
        }

        if (accounts[_accountNumber].walletAddress != _accountNumber) {
            revert PiggyBank__NotValidAccount();
        }

        if (accounts[_accountNumber].exists != true) {
            revert PiggyBank__NotValidAccount();
        }

        _;
    }

    event AccountCreated(address indexed _accountNumber);
    event DepositAlert(address indexed _sender, uint256 _amount);
    event WithdrawalAlert(
        address indexed _sender,
        uint256 _amount,
        uint256 _timestamp
    );

    constructor(address _initialOwner) Ownable(_initialOwner) {
        bankManager = _initialOwner;
    }

    // only bank manager in engine
    function addAccount(address _accountAddress) external {
        if (_accountAddress == address(0)) {
            revert PiggyBank__NotValidAccount();
        }

        if (accounts[_accountAddress].exists) {
            revert PiggBank__MemberAlreadyExists();
        }

        accounts[_accountAddress].exists = true;
        accounts[_accountAddress].walletAddress = _accountAddress;
        accounts[_accountAddress].createdAt = block.timestamp;
        accountNumbersList.push(_accountAddress);

        emit AccountCreated(_accountAddress);
    }

    function deposit(
        uint256 _amount,
        address _sender
    ) external payable onlyAccountHolder(_sender) {
        if (_amount <= 0) {
            revert EtherPiggy__InvalidAmount();
        }

        accounts[_sender].totalBalance += _amount;
        accounts[_sender].deposits[block.timestamp] = _amount;

        emit DepositAlert(_sender, _amount);
    }

    function withdraw(
        address _accountNumber,
        uint256 _amount
    ) external onlyAccountHolder(_accountNumber) {
        if (_amount <= 0) {
            revert EtherPiggy__InvalidAmount();
        }

        (bool success, ) = _accountNumber.call{value: _amount}("");
        accounts[_accountNumber].totalBalance -= _amount;

        if (success != true) {
            revert EtherPiggy__WithdrawalFailed();
        }

        emit WithdrawalAlert(_accountNumber, _amount, block.timestamp);
    }

    // VIEWS
    function getAllAccounts() external view returns (address[] memory) {
        return accountNumbersList;
    }

    function getAccountDetails(
        address _sender
    )
        external
        view
        returns (address walletAddress, uint256 totalBalance, uint256 createdAt)
    {
        if (_sender == address(0)) {
            revert PiggyBank__NotValidAccount();
        }

        AccountDetail storage account = accounts[_sender];

        if (account.walletAddress != _sender) {
            revert PiggyBank__NotValidAccount();
        }

        if (account.exists != true) {
            revert PiggyBank__NotValidAccount();
        }

        return (account.walletAddress, account.totalBalance, account.createdAt);
    }

    // get amount deposited at a time
    function getDepositAmountAtGivenTime(
        address _accountNumber,
        uint256 _timestamp
    ) external view returns (uint256) {
        if (_accountNumber == address(0)) {
            revert PiggyBank__NotValidAccount();
        }

        if (accounts[_accountNumber].exists != true) {
            revert PiggyBank__NotValidAccount();
        }

        return accounts[_accountNumber].deposits[_timestamp];
    }
}
