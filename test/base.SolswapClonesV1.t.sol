// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./helper/BaseClonesTest.sol";

import "src/solswap-clones/factory.sol";
import {Clones} from "@openzeppelin/proxy/Clones.sol";

contract SolswapClonesTest is BaseClonesTest {
    function setUp() public override {
        super.setUp();

        factory = address(new SolFactoryClones());

        // var to avoid verbosity
        _f = IUniswapFactory(factory);

        vm.label(factory, "Factory");

        SolExchange e = new SolExchange();
        vm.expectRevert();
        e.initialize(address(token));

        SolExchange _exchange = SolExchange(payable(Clones.clone(address(e))));
        SolExchange(_exchange).initialize(address(token));

        exchange_address = _f.createExchange(address(token));
        token.approve(exchange_address, type(uint256).max);
    }
}
