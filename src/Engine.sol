// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {ClickCounter} from "./ClickCounter.sol";
import {SaveMyName} from "./SaveMyName.sol";
import {PollStation} from "./PollStation.sol";

contract Engine {
    error Engine__MissingField();

    ClickCounter private clickCounter;
    SaveMyName private saveMyName;
    PollStation private pollStation;

    constructor(
        address _clickCounter,
        address _saveMyName,
        address _pollStation
    ) {
        clickCounter = ClickCounter(_clickCounter);
        saveMyName = SaveMyName(_saveMyName);
        pollStation = PollStation(_pollStation);
    }

    function setSaveMyName(string calldata _name, string calldata _bio) public {
        if (bytes(_name).length == 0 || bytes(_bio).length == 0) {
            revert Engine__MissingField();
        }

        SaveMyName.Person memory _person = SaveMyName.Person({
            name: _name,
            bio: _bio
        });

        saveMyName.setDetails(_person);
    }

    function updateSaveMyName(
        string calldata _name,
        string calldata _bio
    ) public {
        SaveMyName.Person memory _person = SaveMyName.Person({
            name: _name,
            bio: _bio
        });

        saveMyName.updateDetails(_person);
    }

    function getSaveMyName() public view returns (SaveMyName.Person memory) {
        return saveMyName.getPerson();
    }

    function increment() public {
        clickCounter.increment(msg.sender);
    }

    function getCounter() public view returns (uint256) {
        return clickCounter.getNumber(msg.sender);
    }

    /********** POLLSTATION **********/
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

    function getCandidateDetails(uint256 _candidateId) public view {
        pollStation.getCandidateDetails(_candidateId);
    }

    function getTotalCandidates() public view {
        pollStation.getTotalCandidates();
    }

    function getWinner() public view {
        pollStation.getWinner();
    }

    function getUserVote() public view {
        pollStation.getUserVote(msg.sender);
    }

    function hasUserVoted() public view {
        pollStation.hasUserVoted(msg.sender);
    }
}
