// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EtherPiggy is Ownable {
    error PiggyBank__NotValidAccount();
    error PiggBank__MemberAlreadyExists();

    address public bankManager;

    struct AccountDetail {
        address walletAddress;
        uint256 totalBalance;
        // date to amount mapping
        mapping(uint256 => uint256) deposits;
        bool exists;
    }

    mapping(address => AccountDetail) public accounts;

    // onlyAccountHolders
    modifier onlyAccountHolder(address _accountNumber) {
        if (accounts[_accountNumber].walletAddress != msg.sender) {
            revert PiggyBank__NotValidAccount();
        }

        if (_accountNumber == address(0)) {
            revert PiggyBank__NotValidAccount();
        }

        if (accounts[_accountNumber].exists != true) {
            revert PiggyBank__NotValidAccount();
        }

        _;
    }

    event AccountCreated(address indexed _accountNumber);

    constructor(address _initialOwner) public Ownable(_initialOwner) {
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

        emit AccountCreated(_accountAddress);
    }
}
