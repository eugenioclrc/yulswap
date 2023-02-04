// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import "./lib/YulDeployer.sol";

import {IExchange} from "src/interfaces/ExpectedInterfaceExchange.sol";
import "src/interfaces/IUniswapFactory.sol";
import "src/yulswap/factory.sol";

import "src/mocks/Token.sol";

import "./helper/BaseClonesTest.sol";
import {Clones} from "@openzeppelin/proxy/Clones.sol";

contract YulswapTest is BaseClonesTest {
    YulDeployer yulDeployer = new YulDeployer();

    function setUp() public override {
        super.setUp();

        // exchange.yul
        // address demo = yulDeployer.deployContract("exchange");

        factory = address(new YulFactory());

        // var to avoid verbosity
        _f = IUniswapFactory(factory);

        vm.label(factory, "Factory");

        exchange_address = _f.createExchange(address(token));
        token.approve(exchange_address, type(uint256).max);
    }

    function testExchangeMetadata() public override {
        // LP metadata
        IExchange _exchange = IExchange(exchange_address);

        assertEq(_exchange.name(), "Yulswap V1");
        assertEq(_exchange.symbol(), "YUL-V1");
        assertEq(_exchange.decimals(), 18);
    }
}
