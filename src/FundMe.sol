// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.19;
// 2. Imports

// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import {PriceConverter} from "./PriceConverter.sol";

import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**
 * @title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18; //资助的最低数额
    address private immutable i_owner; //合约所有者
    address[] private s_funders; //资助者数组
    mapping(address => uint256) private s_addressToAmountFunded; //资助者资助的金额
    AggregatorV3Interface private s_priceFeed; //函数接口

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        //修饰函数，用于检查是否是合约所有者
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeed) {
        //只会在合约创建时被执行一次，
        s_priceFeed = AggregatorV3Interface(priceFeed); //实例化抽象函数
        i_owner = msg.sender; //合约所有者为合约创建者
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        //资助函数
        require( //检查是否满足最小的资助金额
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, //注意这里的用法
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value; //更新资助者的资助金额
        s_funders.push(msg.sender); //将资助者加入资助队列
    }

    function withdraw() public onlyOwner {
        //合约所有者提取合约的金额
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //将资助队列进行清零并重新进行初始化
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}(""); //进行转账
        require(success); //要求转账成功
    }

    function cheaperWithdraw() public onlyOwner {
        //使用更少gas的提款函数
        address[] memory funders = s_funders; //关键在于对链上的变量读取次数尽量少
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /** Getter Functions */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        //查看资助者的金额
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        //查看喂价的版本
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        //根据索引查看资助队列中的某个资助者地址
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        //查看合约所有者
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        //查看喂价合约
        return s_priceFeed;
    }
}
