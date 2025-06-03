// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 engine_owner;
    }

    NetworkConfig public activeNetworkConfig;

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        // chainId is the id of the current network we are on
        if (block.chainid == 84532) {
            activeNetworkConfig = getBaseSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getBaseSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({engine_owner: vm.envUint("DEV_PRIVATE_KEY")});
    }

    function getOrCreateAnvilEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory anvilConfig = NetworkConfig({engine_owner: DEFAULT_ANVIL_KEY});

        return anvilConfig;
    }
}
