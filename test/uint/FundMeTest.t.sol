//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); //创建一个由“user”衍生的地址，所提供的“user”被作为标签值使用
    uint256 constant SEND_VALUE = 0.1 ether; //发送金额
    uint256 constant STARTING_BALANCE = 10 ether; //初始余额
    uint256 constant GAS_PRICE = 1; //gas费用

    function setUp() external {
        //fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe(); //创建新的部署FundMe的实例
        fundMe = deployFundMe.run(); //在deploy函数中创建新的FundMe实例
        vm.deal(USER, STARTING_BALANCE); //改变USER地址的余额为STARTING_BALANCE
    }

    function testMINIMUM_USDIsFive() public {
        //测试资助的金额是否是5e18
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testPriceFeedVersionIsAccurate() public {
        //测试喂价版本是否是4
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        //测试没有资助足够的金额是否会回滚交易
        vm.expectRevert(); //断言下一次调用会回退
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        //测试资助后，资助者的数据是否更新成功
        vm.prank(USER); //将下一次调用的msg.sender设置为USER地址，仅改变下一次的调用
        fundMe.fund{value: SEND_VALUE}(); //进行资助

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE); //测试两个值是否相等，不相等则测试失败
    }

    function testAddsFunderToArrayOfFunders() public {
        //测试添加资助者功能
        vm.prank(USER); //将下一次调用的msg.sender设置为USER地址，仅改变下一次的调用
        fundMe.fund{value: SEND_VALUE}(); //进行资助

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER); //测试两个值是否相等，不相等则测试失败
    }

    modifier funded() {
        //进行资助，代码重用率较高，使用修饰函数，提高代码效率
        vm.prank(USER); //将下一次调用的msg.sender设置为USER地址，仅改变下一次的调用
        fundMe.fund{value: SEND_VALUE}(); //进行资助
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //测试只有合约所有者才能进行提款
        vm.expectRevert(); //断言下一次调用会回退，不会退则测试失败
        vm.prank(USER); //将下一次调用的msg.sender设置为USER地址，仅改变下一次的调用
        fundMe.withdraw(); //进行提款
    }

    function testWithdrawWithASingleFunder() public funded {
        //测试只有一个资助者时的提款功能
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //合约所有者初始的余额
        uint256 startingFundMeBalance = address(fundMe).balance; //合约的余额

        vm.prank(fundMe.getOwner()); //将下一次调用的msg.sender设置为合约所有者地址，仅改变下一次的调用
        fundMe.withdraw(); //合约所有者进行提款

        uint256 endingOwnerBalance = fundMe.getOwner().balance; //进行提款后，合约所有者的余额
        uint256 endingFundMeBalance = address(fundMe).balance; //进行提款后，合约的余额
        assertEq(endingFundMeBalance, 0); //断言合约的余额为0，否则测试失败
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        ); //断言合约所有者的余额=合约所有者初始的余额+合约的余额，否则测试失败
    }

    function testOwnerIsMsgSender() public {
        //测试合约的所有者是否是合约的创建者
        assertEq(fundMe.getOwner(), msg.sender); //断言合约的所有者是否是合约的创建者，否则测试失败
    }

    function testWithdrawFromMultipleFunders() public funded {
        //测试有多个资助者时的提款功能
        uint160 numberOfFunders = 10; //初始化合约资助者为10人
        uint160 startingFunderIndex = 1; //初始化合约资助者的索引为1
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); //将SEND_VALUE的代币发送给address(i)地址，address(i)是将i转换为address类型
            fundMe.fund{value: SEND_VALUE}(); //进行资助
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //合约所有者初始的余额
        uint256 startingFundMeBalance = address(fundMe).balance; //合约的余额

        vm.startPrank(fundMe.getOwner()); //将下一次调用的msg.sender设置为合约所有者地址
        fundMe.withdraw(); //进行提款
        vm.stopPrank(); //将msg.sender设置为原来的msg.sender
        assert(address(fundMe).balance == 0); //断言合约的余额为0，否则测试失败
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        ); //断言合约所有者的余额=合约所有者初始的余额+合约的余额，否则测试失败
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //测试有多个资助者时的提款功能（更省gas）
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
