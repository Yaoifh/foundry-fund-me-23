//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionTest is Test {
    FundMe fundMe; //声明FundMe实例
    address USER = makeAddr("user"); //创建一个由“user”衍生的地址，所提供的“user”被作为标签值使用
    uint256 constant SEND_VALUE = 0.1 ether; //发送金额
    uint256 constant STARTING_BALANCE = 10 ether; //初始金额
    uint256 constant GAS_PRICE = 1; //gas价格

    function setUp() external {
        //fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe(); //生成新的DeployFundMe实例
        fundMe = deployFundMe.run(); //生成新的FundMe实例
        vm.deal(USER, STARTING_BALANCE); //改变USER地址的余额为STARTING_BALANCE
    }

    function testUesrCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();

        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
