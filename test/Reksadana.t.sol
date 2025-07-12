pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Reksadana} from "../src/Reksadana.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

contract ReksadanaTest is Test {
    Reksadana public reksadana;
    address Andrew = makeAddr("Andrew");
    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    function setUp() public {
        //URL dari alchemy arbitrium project
        vm.createSelectFork(
            "https://arb-mainnet.g.alchemy.com/v2/KluCM3Iw0SfTRWTKxkj93",
            356741300
        );
        reksadana = new Reksadana();
    }

    function test_TotalAsset() public {
        //deal untuk pura pura punya weth dan wbtc
        deal(weth, address(reksadana), 1e18);
        deal(wbtc, address(reksadana), 1e8);

        console.log("Total Asset=", reksadana.totalAssets());
    }
    function test_Deposit() public {
        deal(usdc, Andrew, 1000e6);

        vm.startPrank(Andrew);
        IERC20(usdc).approve(address(reksadana), 1000e6);

        reksadana.deposit(1000e6);

        console.log("Total asset=", reksadana.totalAssets());
        console.log("Total shares=", reksadana.totalSupply());
        console.log("Balance Andrew=", IERC20(reksadana).balanceOf(Andrew));

        vm.stopPrank();
    }

    function test_Withdraw() public {
        deal(usdc, Andrew, 1000e6);

        vm.startPrank(Andrew);
        IERC20(usdc).approve(address(reksadana), 1000e6);

        reksadana.deposit(1000e6);

        uint256 shares = reksadana.balanceOf(Andrew);
        reksadana.withdraw(shares);

        console.log("Andrew USDC Balance: ", IERC20(usdc).balanceOf(Andrew));
        console.log("Andrew Shares Balance: ", reksadana.balanceOf(Andrew));

        assertEq(reksadana.balanceOf(Andrew), 0);
        vm.stopPrank();
    }

    function test_Error_Withdraw() public {
        deal(usdc, Andrew, 1000e6);
        vm.startPrank(Andrew);
        IERC20(usdc).approve(address(reksadana), 1000e6);
        reksadana.deposit(1000e6);

        vm.expectRevert(Reksadana.InsufficientShares.selector);
        reksadana.withdraw(10000e6);
        vm.expectRevert(Reksadana.ZeroAmount.selector);
        reksadana.withdraw(0);
        vm.stopPrank();
    }
}
