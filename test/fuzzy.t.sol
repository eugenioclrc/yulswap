// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {UniV1Bytecode} from "src/uniswapv1/UniV1Bytecode.sol";
import {SolFactory} from "src/solswap/factory.sol";
import {IExchange} from "src/interfaces/ExpectedInterfaceExchange.sol";

import {Token} from "src/mocks/Token.sol";

contract BlackboxFuzzyTest is Test {
    enum FactoryType {
        UniswapV1,
        SolswapV1,
        SolswapV1Clones,
        YulswapV1
    }

    mapping(FactoryType => address) factories;

    function setUp() public {
        UniV1Bytecode uniBytecode = new UniV1Bytecode();
        factories[FactoryType.UniswapV1] = uniBytecode.deployFactory();
        (bool success,) = factories[FactoryType.UniswapV1].call(
            abi.encodeWithSignature("initializeFactory(address)", uniBytecode.deployExchange())
        );
        require(success, "cant initialize factory");

        factories[FactoryType.SolswapV1] = address(new SolFactory());
        factories[FactoryType.SolswapV1Clones] = address(new SolFactory());
        factories[FactoryType.YulswapV1] = address(new SolFactory());
    }

    function _getPrice(address factory, uint96[2] calldata liq, uint256[2] calldata inputs) public returns(uint256[2] memory result) {
        Token tokenA = new Token("token A", "A");
        tokenA.mint(liq[1]);
        
        IExchange _exchangeUniA = IExchange(SolFactory(factory).createExchange(address(tokenA)));
        tokenA.approve(address(_exchangeUniA), type(uint256).max);
        vm.deal(address(this), liq[0]);
        _exchangeUniA.addLiquidity{value: liq[0]}(0, liq[1], type(uint256).max);

        result[0] = _exchangeUniA.getEthToTokenInputPrice(inputs[0]);
        result[1] = _exchangeUniA.getTokenToEthInputPrice(inputs[1]);
        
    }

    function testFuzzyPrice(uint96[2] calldata liq, uint256[2] calldata inputs) public {
        vm.assume(liq[0] > 0);
        vm.assume(liq[1] > 0);
        vm.assume(inputs[0] > 0);
        vm.assume(inputs[1] > 0);

        bool success;

        try this._getPrice(factories[FactoryType.UniswapV1], liq, inputs) returns (uint256[2] memory uniExpected) {
            uint256[2] memory uniYul = _getPrice(factories[FactoryType.YulswapV1], liq, inputs);
            assertEq(
                uniYul[0],
                uniExpected[0]
            ); 
            
            assertEq(
                uniYul[1],
                uniExpected[1]
            );

                } catch {
                    // to be reviewed
                    // vm.expectRevert();
                    // uint256[2] memory uniYul = _getPrice(factories[FactoryType.YulswapV1], liq, inputs);
                }
        
    }
}
