// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {Math} from "@openzeppelin/utils/math/Math.sol";
import "src/interfaces/IUniswapFactory.sol";
import {IExchange} from "src/interfaces/ExpectedInterfaceExchange.sol";
import {BaseTest} from "./BaseTest.sol";

import "src/mocks/Token.sol";

abstract contract BaseClonesTest is BaseTest {
    
    /// @dev basic tests for the factory and exchange
    function testProxyHack() public {
        assertEq(_f.tokenCount(), 1);
        assertEq(_f.getExchange(address(token2)), address(0));

        address _foo = _f.createExchange(address(token2));
        (bool success, ) = _foo.call(abi.encodeWithSignature("initialize(address)", address(token)));
        assertEq(success, false);
        
        assertEq(IExchange(_foo).tokenAddress(), address(token2));
    }
}
