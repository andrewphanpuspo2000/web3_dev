pragma solidity ^0.8.13;
import {Script,console} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {MockUSDC} from "../src/MockUSDC.sol";


contract VaultScript is Script{
    // Vault deployed at: 0x9Ab8A6eC3E481700f6d0e4F4b7a6F61367664056
    // USDC address used: 0xfafA73cb6AC7A08C15310d2606761328176f02F1
   Vault public vault; 
    function setUp() public {


    }
    function run() public{

        vm.startBroadcast();
        MockUSDC usdc =new MockUSDC();
        vault= new Vault(address(usdc));

        console.log("Vault deployed at:", address(vault));
        console.log("USDC address used:", address(usdc));

        vm.stopBroadcast(); 
    } 

}