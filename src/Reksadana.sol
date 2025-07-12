// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//forge install uniswap/v3-periphery untuk ISwapRouter punya Uniswap
import {ISwapRouter} from "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract Reksadana is ERC20 {
    address uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address baseFeed = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address wbtcFeed = 0x6ce185860a4963106506C203335A2910413708e9;
    address wethFeed = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

    error ZeroAmount();
    error InsufficientShares();

    event Deposit(address user, uint256 amount, uint256 shares);
    event Withdraw(address user, uint256 shares, uint256 amount);
    constructor() ERC20("Reksadana", "RKS") {}

    function totalAssets() public view returns (uint256) {
        //ambil harga USDC ke USD
        (, int256 usdcPrice, , , ) = AggregatorV3Interface(baseFeed)
            .latestRoundData();
        //ambil harga WETH ke USD
        (, int256 wethPrice, , , ) = AggregatorV3Interface(wethFeed)
            .latestRoundData();
        uint256 wethInUSD = (uint256(wethPrice) * 1e6) / uint256(usdcPrice);
        //ambil harga WBTC ke USD
        (, int256 wbtcPrice, , , ) = AggregatorV3Interface(wbtcFeed)
            .latestRoundData();
        uint256 wbtcInUSD = (uint256(wbtcPrice) * 1e6) / uint256(usdcPrice);

        uint256 totalWethAsset = (IERC20(weth).balanceOf(address(this)) *
            wethInUSD) / 1e18;
        uint256 totalWbtcAsset = (IERC20(wbtc).balanceOf(address(this)) *
            wbtcInUSD) / 1e8;

        return totalWbtcAsset + totalWethAsset;
    }
    function deposit(uint256 amount) external {
        //check balance
        if (amount == 0) {
            revert ZeroAmount();
        }
        //total asset
        uint256 totalAsset = totalAssets();
        //total shares
        uint256 totalShares = totalSupply();
        //hitung shares yang didapatkan
        uint256 shares = 0;

        if (totalShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalShares) / totalAsset;
        }
        //terima usdc dari user
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        //shares di kirim ke user
        _mint(msg.sender, shares);
        //uniswap ijin untuk mengambil USDC dari smart contract ini
        IERC20(usdc).approve(uniswapRouter, amount);

        //di bagi dua untuk weth dan wbtc
        uint256 amountin = amount / 2;
        //transfer usdc dari user ke uniswap untuk convert ke weth
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdc,
                tokenOut: weth,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountin,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        ISwapRouter(uniswapRouter).exactInputSingle(params);
        //transfer usdc dari user ke uniswap untuk convert ke wbtc
        ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: usdc,
                tokenOut: wbtc,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountin,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        ISwapRouter(uniswapRouter).exactInputSingle(params2);
        //emit event
        emit Deposit(address(msg.sender), amount, shares);
    }

    function withdraw(uint256 shares) external {
        // validation shares tidak boleh 0
        if (shares == 0) {
            revert ZeroAmount();
        }
        // validation user punya shares yang cukup
        if (balanceOf(msg.sender) < shares) {
            revert InsufficientShares();
        }

        // ambil total shares
        uint256 totalShares = totalSupply();

        // Denomination untuk percentage
        uint256 PERCENTAGE_DENOMINATION = 100e16;

        // hitung proporsi berdasarkan percentage
        uint256 proportion = (shares * PERCENTAGE_DENOMINATION) / totalShares;

        // hitung jumlah wbtc yang mau dijual
        uint256 wbtcToSell = (IERC20(wbtc).balanceOf(address(this)) *
            proportion) / PERCENTAGE_DENOMINATION;
        // hitung jumlah weth yang mau dijual
        uint256 wethToSell = (IERC20(weth).balanceOf(address(this)) *
            proportion) / PERCENTAGE_DENOMINATION;

        // ambil shares user via function burn
        _burn(msg.sender, shares);

        // kirim wbtc ke uniswap untuk convert ke usdc
        IERC20(wbtc).approve(uniswapRouter, wbtcToSell);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: wbtc,
                tokenOut: usdc,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wbtcToSell,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        ISwapRouter(uniswapRouter).exactInputSingle(params);

        // kirim weth ke uniswap untuk convert ke usdc
        IERC20(weth).approve(uniswapRouter, wethToSell);
        params = ISwapRouter.ExactInputSingleParams({
            tokenIn: weth,
            tokenOut: usdc,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: wethToSell,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        ISwapRouter(uniswapRouter).exactInputSingle(params);

        // kirim usdc ke user
        uint256 amount = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).transfer(msg.sender, amount);

        // emit event
        emit Withdraw(msg.sender, shares, amount);
    }
}
