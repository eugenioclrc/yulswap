// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SolExchange} from "./exchange.sol";
import {Clones} from "@openzeppelin/proxy/Clones.sol";

contract SolFactoryClones {
    uint256 public tokenCount;
    mapping(address token => address exchange) public getExchange;
    mapping(address exchange => address token) public getToken;
    mapping(uint256 tokenId => address token) public getTokenWithId;

    address private immutable _exchangeImplementation;

    event NewExchange(address indexed token, address indexed exchange);
    error errTokenNotContract();

    constructor() {
        _exchangeImplementation = address(new SolExchange());
    }

    function createExchange(address token) external returns (address exchange) {
        exchange = getExchange[token];
        if (exchange == address(0)) {
            if (token.code.length == 0) revert errTokenNotContract();

            exchange = Clones.clone(address(_exchangeImplementation));
            SolExchange(exchange).initialize(token);

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
