// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SolExchange} from "./exchange.sol";

contract SolFactory {
    uint256 public tokenCount;
    mapping(address token => address payable exchange) public getExchange;
    mapping(address exchange => address token) public getToken;
    mapping(uint256 tokenId => address token) public getTokenWithId;

    event NewExchange(address indexed token, address indexed exchange);
    error errTokenNotContract();

    function createExchange(address token) external returns (address payable exchange) {
        exchange = payable(getExchange[token]);
        if (exchange == address(0)) {
            if (token.code.length == 0) {
                revert errTokenNotContract();
            }
            exchange = payable(address(new SolExchange(token)));

            unchecked {
                // overflow is virtually impossible, inline increment and assignation for gas saving
                getTokenWithId[++tokenCount] = token;
            }

            getExchange[token] = exchange;
            getToken[exchange] = token;
            emit NewExchange(token, exchange);
        }
    }
}
