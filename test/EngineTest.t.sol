// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ClickCounter} from "../src/ClickCounter.sol";
import {DeployEngine} from "../script/DeployEngine.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {SaveMyName} from "../src/SaveMyName.sol";
import {Engine} from "../src/Engine.sol";

contract EngineTest is Test {
    DeployEngine deployer;
    Engine engine;
    SaveMyName saveMyName;
    ClickCounter public clickCounter;
    HelperConfig helperConfig;

    address owner;

    // address user;

    function setUp() public {
        deployer = new DeployEngine();
        owner = address(1);
        // user = makeAddr("user");

        // Deploy contracts using test-friendly method
        (engine, clickCounter, saveMyName) = deployer.deployForTest(owner);

        // Transfer ownership as the test owner
        vm.startPrank(owner);
        clickCounter.transferOwnership(address(engine));
        saveMyName.transferOwnership(address(engine));
        vm.stopPrank();
    }

    function testDeployment() public view {
        assert(address(engine) != address(0));
        assert(address(saveMyName) != address(0));
        assert(address(clickCounter) != address(0));

        // Check ownership was transferred
        assert(clickCounter.owner() == address(engine));
        assert(saveMyName.owner() == address(engine));
    }

    function testIncrement() public {
        address user = makeAddr("user");

        // assert the number is 0
        vm.prank(user);
        assertEq(clickCounter.numbers(user), 0);

        // call increment
        vm.prank(user);
        engine.increment();

        assertEq(clickCounter.numbers(user), 1);

        // vm.prank(user);
        // engine.increment();

        // assertEq(clickCounter.numbers(address(this)), 2);
    }
}
