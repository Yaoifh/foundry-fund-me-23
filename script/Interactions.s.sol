//SPDX-License-Identifier:MIT

//fund
//withdraw

pragma solidity ^0.8.18;
import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    //资助FundMe
    uint256 constant SEND_VALUE = 0.01 ether; //发送的金额

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast(); //函数使用调用该函数的合约地址作为发送方
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}(); //向FundMe合约资助
        vm.stopBroadcast(); //函数不再使用调用该函数的合约地址作为发送方
        console.log("Funded FundMe with %s", SEND_VALUE); //在控制台打印资助金额
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        ); //调用最近部署的FundMe函数
        vm.startBroadcast(); //函数使用调用该函数的合约地址作为发送方
        fundFundMe(mostRecentlyDeployed); //调用fundFundMe函数
        vm.stopBroadcast(); //函数不再使用调用该函数的合约地址作为发送方
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw(); //向FundMe合约提款
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        ); //调用最近部署的FundMe函数

        withdrawFundMe(mostRecentlyDeployed); //调用withdraw函数
    }
}
