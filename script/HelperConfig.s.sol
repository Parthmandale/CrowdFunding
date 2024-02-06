// Helper config will help deploy mock when we are local anivil chain or any other mainnet or testnet chain
// now we dont need to hadcore address while deployment

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MockV3Aggregator} from "../test/mocks/MockV3Aggregtor.sol";
import {Script} from "forge-std/Script.sol";
// is script because we are using deployment for anvil chain which uses all script files

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed; // eth/usd price Feed
    }

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            // sepolia chain id
            activeNetworkConfig = getSepoiaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoiaEthConfig() public pure returns (NetworkConfig memory) {
        // priceFeed is of SEPOLIA/USD
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306}); // to specify we can use {} inside () in struct
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethCOnfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethCOnfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // on anvil it is isnt easy as other aboove because here we will have to deploy it by ourself
        //1) Deply Mock, fake contract 2) Return the Mock address
        // to deploy those mock(our own priceFeed) we can use deploy script here using vm.startBroadcast() and vm.stopBroadcast()

        // to avoid deploying new one gain and again -
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
