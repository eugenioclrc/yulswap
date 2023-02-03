// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import "./lib/YulDeployer.sol";

import {IExchange} from "src/interfaces/ExpectedInterfaceExchange.sol";
import "src/interfaces/IUniswapFactory.sol";
import "src/yulswap/factory.sol";

import "src/mocks/Token.sol";

import "./helper/BaseTest.sol";
import {Clones} from "@openzeppelin/proxy/Clones.sol";


contract YulswapTest is BaseTest {
    YulDeployer yulDeployer = new YulDeployer();

    
    function setUp() public override {
        super.setUp();

        // exchange.yul
        yulDeployer.deployContract("exchange");
        
        factory = address(new YulFactory());

        // var to avoid verbosity
        _f = IUniswapFactory(factory);

        vm.label(factory, "Factory");

        
        exchange_address = _f.createExchange(address(token));
        token.approve(exchange_address, type(uint256).max);
    }
}
