// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ClickCounter} from "../src/ClickCounter.sol";
import {SaveMyName} from "../src/SaveMyName.sol";
import {PollStation} from "../src/PollStation.sol";
import {Engine} from "../src/Engine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEngine is Script {
    Engine public engine;

    function run()
        external
        returns (Engine, PollStation, SaveMyName, ClickCounter, HelperConfig)
    {
        HelperConfig helperConfig = new HelperConfig();

        uint engine_owner = helperConfig.activeNetworkConfig();

        // Convert private key to address for owner
        address owner = vm.addr(engine_owner);

        vm.startBroadcast(engine_owner);

        (
            Engine deployedEngine,
            ClickCounter clickCounter,
            SaveMyName saveMyName,
            PollStation pollStation
        ) = deployContracts(owner);

        clickCounter.transferOwnership(address(deployedEngine));
        saveMyName.transferOwnership(address(deployedEngine));

        vm.stopBroadcast();

        return (
            deployedEngine,
            pollStation,
            saveMyName,
            clickCounter,
            helperConfig
        );
    }

    // Test-friendly deployment function - no broadcasting
    function deployForTest(
        address testOwner
    ) external returns (Engine, ClickCounter, SaveMyName, PollStation) {
        return deployContracts(testOwner);
    }

    // Internal deployment logic
    function deployContracts(
        address owner
    ) internal returns (Engine, ClickCounter, SaveMyName, PollStation) {
        ClickCounter clickCounter = new ClickCounter(owner);
        SaveMyName saveMyName = new SaveMyName(owner);
        PollStation pollStation = new PollStation(owner);
        Engine deployedEngine = new Engine(
            address(clickCounter),
            address(saveMyName),
            address(pollStation)
        );

        return (deployedEngine, clickCounter, saveMyName, pollStation);
    }
}
