// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {NFTContract} from "./../../src/NFTContract.sol";

contract HelperConfig is Script {
    // deployment arguments
    address public constant TOKENOWNER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    string public constant NAME = "PigeonPark";
    string public constant SYMBOL = "PGENZ";
    string public constant BASE_URI =
        "ipfs://bafybeih7jkpoqds2kt5mhkgzfmbxngvo2xhc2jsr4rrca3oqrxvwduf3za/";
    string public constant BASIC_URI =
        "ipfs://bafybeibhkj36dnnqpa66oek4t3kox7j2yzuaibqcwi5vqxhlh5sdswu5ia/";
    string public constant TEAM_URI =
        "ipfs://bafybeidtn2f7hwjsegds4aawkfuecre65zffqun6mmktzxbkb4gmcnremq/";

    string public constant CONTRACT_URI =
        "ipfs://bafybeigioiijicnv6mghzkml6ollohopcdvjvkvgjjghbjfvnwixkdd27m/contractMetadata";

    uint256 public constant MAX_SUPPLY = 1940;

    uint256 public constant TOKEN_FEE = 0;
    uint256 public constant ETH_FEE = 0.05 ether;
    uint96 public constant ROYALTY = 250;

    // chain configurations
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        NFTContract.ConstructorArguments args;
    }

    constructor() {
        if (block.chainid == 1 /** ethereum */) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 11155111 /** sepolia */) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getActiveNetworkConfigStruct()
        public
        view
        returns (NetworkConfig memory)
    {
        return activeNetworkConfig;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0xda65502E913e81544E54693EB0b8e950104951C8,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    feeAddress: 0xF143532C28F73590a737FF20Ad34bC9758d70c56,
                    tokenAddress: 0x2D17B511A85B401980CC0FEd15A8D57FDb8EEc60,
                    baseURI: BASE_URI,
                    basicURI: BASIC_URI,
                    teamURI: TEAM_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0x11F392Ba82C7d63bFdb313Ca63372F6De21aB448,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    feeAddress: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF,
                    tokenAddress: 0xfDA030107EB1de41aE233992c84A6e9C99d3Ca34,
                    baseURI: BASE_URI,
                    basicURI: BASIC_URI,
                    teamURI: TEAM_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contract
        vm.startBroadcast();
        ERC20Token token = new ERC20Token(TOKENOWNER);
        vm.stopBroadcast();

        return
            NetworkConfig({
                args: NFTContract.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    feeAddress: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                    tokenAddress: address(token),
                    baseURI: BASE_URI,
                    basicURI: BASIC_URI,
                    teamURI: TEAM_URI,
                    contractURI: CONTRACT_URI,
                    maxSupply: MAX_SUPPLY,
                    royaltyNumerator: ROYALTY
                })
            });
    }
}
