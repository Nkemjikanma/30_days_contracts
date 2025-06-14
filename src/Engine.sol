// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ClickCounter} from "./ClickCounter.sol";
import {SaveMyName} from "./SaveMyName.sol";
import {PollStation} from "./PollStation.sol";
import {AuctionHouse} from "./AuctionHouse.sol";
import {AdminOnly} from "./AdminOnly.sol";
import {EtherPiggy} from "./EtherPiggy.sol";
import {IOU} from "./IOU.sol";

contract Engine {
    error Engine__MissingField();
    error Engine__NotAuthorizedToCallEngine();
    error Engine__InvalidAmount();
    error Engine__InvalidAddress();

    ClickCounter private clickCounter;
    SaveMyName private saveMyName;
    PollStation private pollStation;
    AuctionHouse private auctionHouse;
    AdminOnly private adminOnly;
    EtherPiggy private etherPiggy;
    IOU private iOU;

    address public engineOwner;

    modifier onlyEngineOwner() {
        if (msg.sender != engineOwner) {
            revert Engine__NotAuthorizedToCallEngine();
        }
        _;
    }

    constructor(
        address _clickCounter,
        address _saveMyName,
        address _pollStation,
        address _auctionHouse,
        address _adminOnly,
        address _etherPiggy,
        address _engineOwner,
        address _iOU
    ) {
        clickCounter = ClickCounter(_clickCounter);
        saveMyName = SaveMyName(_saveMyName);
        pollStation = PollStation(_pollStation);
        auctionHouse = AuctionHouse(_auctionHouse);
        adminOnly = AdminOnly(_adminOnly);
        etherPiggy = EtherPiggy(payable(_etherPiggy));
        iOU = IOU(payable(_iOU));

        engineOwner = _engineOwner;
    }

    /**
     * ClickCounter *********
     */
    function increment() public {
        clickCounter.increment(msg.sender);
    }

    function setNumber(uint256 _number) public {
        clickCounter.setNumber(_number, msg.sender);
    }

    function getCounter() public view returns (uint256) {
        return clickCounter.getNumber(msg.sender);
    }

    /**
     * SaveMyName ************
     */
    function setSaveMyName(string calldata _name, string calldata _bio) public {
        if (bytes(_name).length == 0 || bytes(_bio).length == 0) {
            revert Engine__MissingField();
        }

        SaveMyName.Person memory _person = SaveMyName.Person({name: _name, bio: _bio});

        saveMyName.setDetails(_person, msg.sender);
    }

    function updateSaveMyName(string calldata _name, string calldata _bio) public {
        SaveMyName.Person memory _person = SaveMyName.Person({name: _name, bio: _bio});

        saveMyName.updateDetails(_person, msg.sender);
    }

    function getSaveMyName() public view returns (SaveMyName.Person memory) {
        return saveMyName.getPerson(msg.sender);
    }

    /**
     * POLLSTATION *********
     */
    function addCandidate(string calldata _name, string calldata _party) public {
        pollStation.addCandidate(_name, _party);
    }

    function setVoting() public {
        pollStation.setVoting();
    }

    function castVote(uint256 _candidateId) public {
        pollStation.castVote(_candidateId, msg.sender);
    }

    function getCandidateDetails(uint256 _candidateId) public view returns (PollStation.Candidate memory) {
        return pollStation.getCandidateDetails(_candidateId);
    }

    function getTotalCandidates() public view returns (uint256) {
        return pollStation.getTotalCandidates();
    }

    function getWinner() public view returns (PollStation.Candidate memory) {
        return pollStation.getWinner();
    }

    function getUserVote() public view returns (PollStation.Candidate memory) {
        return pollStation.getUserVote(msg.sender);
    }

    function hasUserVoted() public view returns (bool) {
        return pollStation.hasUserVoted(msg.sender);
    }

    /**
     * AuctionHouse *********
     */
    function createAuction(
        string calldata _name,
        string calldata _description,
        uint256 _startingPrice,
        uint256 _durationInMinutes,
        address _seller
    ) public returns (uint256) {
        uint256 _auctionItemId =
            auctionHouse.createAuction(_name, _description, _startingPrice, _durationInMinutes, _seller);

        return _auctionItemId;
    }

    function placeBid(uint256 _auctionId, uint256 _amount, address _bidder) public {
        auctionHouse.placeBid(_auctionId, _amount, _bidder);
    }

    function endAuction(uint256 _auctionId, address _seller) public {
        auctionHouse.endAuction(_auctionId, _seller);
    }

    function cancelAuction(uint256 _auctionId, address _seller) public {
        auctionHouse.cancelAuction(_auctionId, _seller);
    }

    function getAuctionDetails(uint256 _auctionId)
        public
        view
        returns (string memory, string memory, uint256, uint256, bool, uint256, address, bool)
    {
        return auctionHouse.getAuctionDetails(_auctionId);
    }

    function getBids(uint256 _auctionId) public view returns (AuctionHouse.Bid[] memory) {
        return auctionHouse.getBids(_auctionId);
    }

    function getBidders(uint256 _auctionId) public view returns (address[] memory) {
        return auctionHouse.getBidders(_auctionId);
    }

    function getMyBids() public view returns (uint256[] memory) {
        return auctionHouse.getMyBids(msg.sender);
    }

    function getMyAuctions() public view returns (uint256[] memory) {
        return auctionHouse.getMyAuctions(msg.sender);
    }

    /**
     * AdminOnly *******
     */
    function addTreasure(uint256 _amount) public onlyEngineOwner {
        adminOnly.addTreasure(_amount, address(this));
    }

    function approveWithdrawal(uint256 _amount, address _newTreasurer) public onlyEngineOwner {
        adminOnly.approveWithdrawal(_newTreasurer, _amount);
    }

    function withdrawTreasure(uint256 _amount) public {
        adminOnly.withdrawTreasure(_amount, msg.sender);
    }

    function resetWithdrawStatus() public {
        adminOnly.resetWithdrawStatus(address(this), msg.sender);
    }

    function transferOwnership(address _newAdmin) public {
        adminOnly.transferOwnership(address(this), _newAdmin);
    }

    // ADMIN ONLY - VIEWS
    function getTotalTreasure() public view returns (uint256) {
        return adminOnly.getTotalTreasure();
    }

    function getWithdrawlAllowance() public view returns (uint256) {
        return adminOnly.getWithdrawalAllowance(msg.sender);
    }

    function getHasUserWithdrawn() public view returns (bool) {
        return adminOnly.hasUserWithdrawn(msg.sender);
    }

    function getOwner() public view returns (address) {
        return adminOnly.getOwner();
    }

    /**
     * EtherPiggy *******
     */
    // onlyEngineOwner is our manager in this case
    function addAccount(address _newAccountAddress) public onlyEngineOwner {
        etherPiggy.addAccount(_newAccountAddress);
    }

    function deposit(uint256 _amount) public payable {
        if (msg.value != _amount) {
            revert Engine__InvalidAmount();
        }
        etherPiggy.deposit{value: msg.value}(_amount, msg.sender);
    }

    function withdraw(uint256 _amount) public {
        etherPiggy.withdraw(msg.sender, _amount);
    }

    function getAllAccounts() public view returns (address[] memory) {
        return etherPiggy.getAllAccounts();
    }

    function getDepositAmount(uint256 _timestamp, address _accountNumber) public view returns (uint256) {
        return etherPiggy.getDepositAmountAtGivenTime(_accountNumber, _timestamp);
    }

    /**
     * IOU *******
     */
    function addMember(address _newMember) public onlyEngineOwner {
        if (_newMember == address(0)) {
            revert Engine__InvalidAddress();
        }
        iOU.addMember(_newMember);
    }

    function iOUDepost(uint256 _amount) public payable {
        if (msg.value != _amount) {
            revert Engine__InvalidAmount();
        }

        iOU.deposit{value: msg.value}(msg.sender, _amount);
    }

    function createDebt(address _debtor, uint256 _amount, string calldata _desc) public {
        iOU.createDebt(msg.sender, _debtor, _amount, _desc);
    }

    function respondToDebt(uint256 _debtId, bool _isApproved) public {
        iOU.respondToDebtClaim(msg.sender, _debtId, _isApproved);
    }

    function settleDebt(address _creditor, uint56 _debtId, uint256 _amount) public payable {
        if (msg.value != _amount) {
            revert Engine__InvalidAmount();
        }

        iOU.settleDebt{value: msg.value}(msg.sender, _creditor, _debtId, _amount);
    }

    function getMyDebts() public view returns (IOU.Debt[] memory) {
        iOU.getMyDebts(msg.sender);
    }

    function getDebtsOwedToMe() public view returns (IOU.Debt[] memory) {
        iOU.getDebtsOwedToMe(msg.sender);
    }
}
