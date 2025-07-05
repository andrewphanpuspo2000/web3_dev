// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC20{

 address public usdc;
 
 error InsufficientBalance();

 event Deposit(address indexed user, uint256 amount);
 event Withdraw(address indexed user, uint256 amount);
 event DistributeYield(address indexed user, uint256 amount);
 event TestEvent(uint256 indexed param1,uint256 indexed param2,uint256 indexed param3,uint256 param4);
 constructor(address _usdc) ERC20 ("Vault","VLT"){
    usdc = _usdc;
 }
 
//msg.sender is the address of user who deposit the money
 function deposit (uint256 amount) external {
  if(IERC20(usdc).balanceOf(msg.sender) < amount){
     revert InsufficientBalance();

     //require(IERC20(usdc).balanceOf(msg.sender) >= amount,"Transfer amount exceeds allowance");
    }
    uint256 totalAssets= IERC20(usdc).balanceOf(address(this));
    uint256 totalShares= totalSupply();

    uint256 shares=0;

    if(totalShares == 0){
       shares=amount;
    }else{
     shares= amount * totalShares/totalAssets;
     
    }
    //mint is for sending user our tokens
    _mint(msg.sender,shares);
    //to take USDC from depositor to our address
    IERC20(usdc).transferFrom(msg.sender,address(this),amount);
    //receipt once finish process
    emit Deposit(msg.sender,amount);

 }

 function withdraw(uint256 shares) external {
   if(balanceOf(msg.sender) < shares){
     revert InsufficientBalance();
    }
    uint256 totalAssets= IERC20(usdc).balanceOf(address(this));
    uint256 totalShares= totalSupply();
   
    uint256 amount= shares * totalAssets/totalShares;

    //ambil token dari user
    _burn(msg.sender,shares);

    IERC20(usdc).transfer(msg.sender,amount);
      //receipt once finish process
    emit Withdraw(msg.sender,amount);
 }
   function distributeYield(uint256 amount) external {
      //use only balance of because check token of vault
      if(IERC20(usdc).balanceOf(msg.sender) < amount){
        revert InsufficientBalance();
    }
     IERC20(usdc).transferFrom(msg.sender,address(this),amount);
     emit DistributeYield(msg.sender,amount);

 }

 function CallTestEvent() public{

    emit TestEvent(1,2,3,4);
 }
}