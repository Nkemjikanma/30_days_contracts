// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ClickCounter} from "../src/ClickCounter.sol";
import {DeployEngine} from "../script/DeployEngine.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {SaveMyName} from "../src/SaveMyName.sol";
import {Engine} from "../src/Engine.sol";
import {PollStation} from "../src/PollStation.sol";

contract EngineTest is Test {
    DeployEngine deployer;
    Engine engine;
    PollStation pollStation;
    SaveMyName saveMyName;
    ClickCounter public clickCounter;
    HelperConfig helperConfig;

    address owner;

    function setUp() public {
        deployer = new DeployEngine();
        owner = address(1);

        // Deploy contracts using test-friendly method
        (engine, clickCounter, saveMyName, pollStation) = deployer.deployForTest(owner);

        // Transfer ownership as the test owner
        vm.startPrank(owner);
        clickCounter.transferOwnership(address(engine));
        saveMyName.transferOwnership(address(engine));
        pollStation.transferOwnership(address(engine));
        vm.stopPrank();
    }

    function testDeployment() public view {
        assert(address(engine) != address(0));
        assert(address(saveMyName) != address(0));
        assert(address(clickCounter) != address(0));

        // Check ownership was transferred
        assert(clickCounter.owner() == address(engine));
        assert(saveMyName.owner() == address(engine));
        assert(pollStation.owner() == address(engine));
    }

    /**
     * ClickCounter *******
     */
    function testIncrement() public {
        address user = makeAddr("user");

        // assert the number is 0
        vm.prank(user);
        assertEq(clickCounter.numbers(user), 0);

        // call increment
        vm.prank(user);
        engine.increment();

        assertEq(clickCounter.numbers(user), 1);
        vm.prank(user);
        engine.getCounter();

        vm.prank(user);
        engine.increment();

        vm.prank(user);
        engine.getCounter();

        assertEq(clickCounter.numbers(user), 2);
    }

    function testSetNumber() public {
        address user = makeAddr("user");
        vm.prank(user);

        engine.setNumber(10);

        assertEq(clickCounter.numbers(user), 10);
    }

    /**
     * SaveMyName *******
     */
    function testSetMyName() public {
        string memory name = "Nkem";
        string memory bio = "I am a dev";

        address user = makeAddr("user");

        vm.prank(user);
        engine.setSaveMyName(name, bio);

        vm.prank(user);
        SaveMyName.Person memory person = engine.getSaveMyName();

        assertEq(person.name, name);
        assertEq(person.bio, bio);
    }

    function testUpdateMyName() public {
        string memory name = "Nkem";
        string memory bio = "I am a dev";

        string memory name2 = "Charles";
        string memory bio2 = "I don't know";

        address user = makeAddr("user");

        vm.prank(user);
        engine.setSaveMyName(name, bio);

        vm.prank(user);
        engine.updateSaveMyName(name2, bio2);

        vm.prank(user);
        SaveMyName.Person memory person = engine.getSaveMyName();

        assertEq(person.name, name2);
        assertEq(person.bio, bio2);
    }

    /**
     * PollStation *******
     */
    function testAddCandidate() public {
        string memory name = "T Pain";
        string memory party = "APC";

        // initial number of candidates
        uint256 initialCandidateCount = pollStation.getTotalCandidates();

        engine.addCandidate(name, party);

        // check candidate count has increased
        assertEq(pollStation.getTotalCandidates(), initialCandidateCount + 1);

        PollStation.Candidate memory candidate = pollStation.getCandidateDetails(initialCandidateCount);

        assertEq(candidate.name, name);
        assertEq(candidate.party, party);
        assertEq(candidate.number_of_votes, 0);
    }

    function testSetVoting() public {
        bool initialVotingStatus = pollStation.votingOpen();

        assertEq(initialVotingStatus, false);

        engine.setVoting();

        bool currentVotingStatus = pollStation.votingOpen();
        assertEq(currentVotingStatus, true);

        engine.setVoting();
        bool finalVotingStatus = pollStation.votingOpen();

        assertEq(finalVotingStatus, false);
    }

    function testCastVote() public {
        address user = makeAddr("user");
        string memory candidate1 = "T Pain";
        string memory party1 = "APC";

        string memory candidate2 = "Obi";
        string memory party2 = "Labour";

        engine.addCandidate(candidate1, party1);
        engine.addCandidate(candidate2, party2);

        engine.setVoting();

        vm.prank(user);
        engine.castVote(1);

        PollStation.Candidate memory voted = engine.getCandidateDetails(1);
        assertEq(voted.name, candidate2);
        assertEq(voted.party, party2);
        assertEq(voted.number_of_votes, 1);
    }

    function testGetWinner() public {
        address user = makeAddr("user");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        string memory candidate1 = "T Pain";
        string memory party1 = "APC";

        string memory candidate2 = "Obi";
        string memory party2 = "Labour";

        engine.addCandidate(candidate1, party1);
        engine.addCandidate(candidate2, party2);

        engine.setVoting();

        vm.prank(user);
        engine.castVote(1);
        vm.prank(user2);
        engine.castVote(1);
        vm.prank(user3);
        engine.castVote(1);

        PollStation.Candidate memory winner = engine.getWinner();
        assertEq(winner.name, candidate2);
        assertEq(winner.party, party2);
        assertEq(winner.number_of_votes, 3);
    }

    function testGetUserVote() public {
        address user = makeAddr("user");
        string memory candidate1 = "T Pain";
        string memory party1 = "APC";

        string memory candidate2 = "Obi";
        string memory party2 = "Labour";

        engine.addCandidate(candidate1, party1);
        engine.addCandidate(candidate2, party2);

        engine.setVoting();

        vm.prank(user);
        engine.castVote(1);

        vm.prank(user);

        PollStation.Candidate memory voted = engine.getUserVote();
        assertEq(voted.name, candidate2);
        assertEq(voted.party, party2);
        assertEq(voted.number_of_votes, 1);
    }

    function testHasUserVoted() public {
        address user = makeAddr("user");
        string memory candidate1 = "T Pain";
        string memory party1 = "APC";

        string memory candidate2 = "Obi";
        string memory party2 = "Labour";

        engine.addCandidate(candidate1, party1);
        engine.addCandidate(candidate2, party2);

        engine.setVoting();

        vm.prank(user);
        engine.castVote(1);

        vm.prank(user);
        bool hasVoted = engine.hasUserVoted();
        assertEq(hasVoted, true);
    }
}
