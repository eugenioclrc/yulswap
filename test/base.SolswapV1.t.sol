// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./helper/BaseTest.sol";

import "src/solswap/factory.sol";

contract SolswapTest is BaseTest {
    function setUp() public override {
        super.setUp();

        factory = address(new SolFactory());

        // var to avoid verbosity
        _f = IUniswapFactory(factory);

        vm.label(factory, "Factory");

        exchange_address = _f.createExchange(address(token));
        token.approve(exchange_address, type(uint256).max);
    }
}
