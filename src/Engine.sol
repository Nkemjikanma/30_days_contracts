// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ClickCounter} from "./ClickCounter.sol";
import {SaveMyName} from "./SaveMyName.sol";
import {PollStation} from "./PollStation.sol";
import {AuctionHouse} from "./AuctionHouse.sol";

contract Engine {
    error Engine__MissingField();

    ClickCounter private clickCounter;
    SaveMyName private saveMyName;
    PollStation private pollStation;
    AuctionHouse private auctionHouse;

    constructor(
        address _clickCounter,
        address _saveMyName,
        address _pollStation,
        address _auctionHouse
    ) {
        clickCounter = ClickCounter(_clickCounter);
        saveMyName = SaveMyName(_saveMyName);
        pollStation = PollStation(_pollStation);
        auctionHouse = AuctionHouse(_auctionHouse);
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

        SaveMyName.Person memory _person = SaveMyName.Person({
            name: _name,
            bio: _bio
        });

        saveMyName.setDetails(_person, msg.sender);
    }

    function updateSaveMyName(
        string calldata _name,
        string calldata _bio
    ) public {
        SaveMyName.Person memory _person = SaveMyName.Person({
            name: _name,
            bio: _bio
        });

        saveMyName.updateDetails(_person, msg.sender);
    }

    function getSaveMyName() public view returns (SaveMyName.Person memory) {
        return saveMyName.getPerson(msg.sender);
    }

    /**
     * POLLSTATION *********
     */
    function addCandidate(
        string calldata _name,
        string calldata _party
    ) public {
        pollStation.addCandidate(_name, _party);
    }

    function setVoting() public {
        pollStation.setVoting();
    }

    function castVote(uint256 _candidateId) public {
        pollStation.castVote(_candidateId, msg.sender);
    }

    function getCandidateDetails(
        uint256 _candidateId
    ) public view returns (PollStation.Candidate memory) {
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
     * POLLSTATION *********
     */
}
