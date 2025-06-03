// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PollStation is Ownable {
    error PollStation__MissingFields();
    error PollStation__VotingAlreadyInProgress();
    error PollStation__VotingIsNotOpen();
    error PollStation__VotedAlready();
    error PollStation__InvalidCandidate();

    struct Candidate {
        string name;
        string party;
        uint256 number_of_votes;
    }

    // all candidates
    Candidate[] public candidates;

    //  track which address voted for which candidate
    mapping(address => uint256) public voterToCandidateId;

    //track if address has voted
    mapping(address => bool) public hasVoted;

    // total votes
    uint256 public totalVotes;

    // voting status
    bool public votingOpen;

    modifier isvotingOpen() {
        if (votingOpen != true) {
            revert PollStation__VotingIsNotOpen();
        }

        _;
    }

    modifier CheckVoted(address sender) {
        if (hasVoted[sender]) {
            revert PollStation__VotedAlready();
        }

        _;
    }

    modifier validateCandidate(uint256 _candidateId) {
        if (_candidateId > candidates.length) {
            revert PollStation__InvalidCandidate();
        }

        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    function addCandidate(string calldata _name, string calldata _party) external onlyOwner {
        if (bytes(_name).length == 0 && bytes(_party).length == 0) {
            revert PollStation__MissingFields();
        }

        Candidate memory newCandidate = Candidate({name: _name, party: _party, number_of_votes: 0});

        candidates.push(newCandidate);
    }

    function setVoting() external onlyOwner {
        // if voting is true, set to false, if is false, set to true
        if (votingOpen == true) {
            votingOpen = false;
        } else {
            votingOpen = true;
        }
    }

    function castVote(uint256 _candidateId, address _sender)
        external
        isvotingOpen
        CheckVoted(_sender)
        validateCandidate(_candidateId)
    {
        // vote
        candidates[_candidateId].number_of_votes += 1;

        // set has voted
        hasVoted[_sender] = true;

        // set who the address has voted for
        voterToCandidateId[_sender] = _candidateId;
    }

    function getCandidateDetails(uint256 _candidateId)
        external
        view
        validateCandidate(_candidateId)
        returns (Candidate memory)
    {
        return candidates[_candidateId];
    }

    function getTotalCandidates() external view returns (uint256) {
        return candidates.length;
    }

    function getWinner() external view returns (Candidate memory) {
        Candidate memory winning_candidate = candidates[0];
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].number_of_votes > winning_candidate.number_of_votes) {
                winning_candidate = candidates[i];
            }
        }

        return winning_candidate;
    }

    function getUserVote(address _voter) external view returns (Candidate memory) {
        return candidates[voterToCandidateId[_voter]];
    }

    function hasUserVoted(address _voter) external view returns (bool) {
        return hasVoted[_voter];
    }
}
