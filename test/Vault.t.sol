// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Vault} from "../src/Vault.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract VaultTest is Test {
    MockUSDC public usdc;
    Vault public vault;
    address public alice = makeAddr("test");

    function setUp() public {
        usdc = new MockUSDC();
        vault = new Vault(address(usdc));
    }
    function test_Deposit() public {
        vm.startPrank(alice);
        //console.log(alice);
        usdc.mint(alice, 1000);
        usdc.approve(address(vault), 1000);
        vm.expectEmit(true, true, true, true);
        emit Vault.Deposit(alice, 1000);

        //Deposit to vault as alice
        vault.deposit(1000);
        assertEq(vault.balanceOf(alice), 1000);

        vm.stopPrank();
    }

    function test_Withdraw() public {
        //Alice deposit 1000 usdc
        vm.startPrank(alice);
        usdc.mint(alice, 1000);
        usdc.approve(address(vault), 1000);

        //expect emit deposit
        vm.expectEmit(true, true, true, true);
        emit Vault.Deposit(alice, 1000);

        //Deposit to vault as alice
        vault.deposit(1000);
        assertEq(vault.balanceOf(alice), 1000);

        vm.stopPrank();

        //DistributeYield
        usdc.mint(address(this), 1000);
        usdc.approve(address(vault), 1000);
        // console.log(usdc.balanceOf(address(this)));
        //expect emit distribute yield
        vm.expectEmit(true, true, true, true);
        emit Vault.DistributeYield(address(this), 1000);

        //Distribute 1000 USDC
        vault.distributeYield(1000);
        //check balance of vault
        assertEq(usdc.balanceOf(address(vault)), 2000);

        //expect emit withdraw event
        vm.expectEmit(true, true, true, true);
        emit Vault.Withdraw(address(alice), 1000);
        //withdraw 500 USDC
        vm.prank(alice);
        vault.withdraw(500);
        assertEq(usdc.balanceOf(address(alice)), 1000);
    }

    function test_CallTestEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Vault.TestEvent(1, 2, 3, 4);
        vault.CallTestEvent();
    }
}
