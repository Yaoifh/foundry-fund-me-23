//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); //读取动态的网络配置：喂价网络的合约地址
        vm.startBroadcast(); //函数将使用调用该合约的地址作为发送方地址
        FundMe fundMe = new FundMe(ethUsdPriceFeed); //创建新的FundMe合约实例
        vm.stopBroadcast(); //函数不再将使用调用该合约的地址作为发送方地址
        return fundMe;
    }
}
