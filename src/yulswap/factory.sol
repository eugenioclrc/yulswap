// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {YulExchange} from "./exchange.sol";
import {LibClone} from "solady/utils/LibClone.sol";

contract YulFactory {
    // from https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args/blob/main/src/ExampleCloneFactory.sol
    uint256 public tokenCount;
    mapping(address token => address payable exchange) public getExchange;
    mapping(address exchange => address token) public getToken;
    mapping(uint256 tokenId => address token) public getTokenWithId;

    address private immutable _exchangeImplementation;

    event NewExchange(address indexed token, address indexed exchange);
    error errTokenNotContract();

    constructor() {
        _exchangeImplementation = address(new YulExchange());
    }

    function createExchange(address token) external returns (address payable exchange) {
        exchange = payable(getExchange[token]);
        if (exchange == address(0)) {
            // add check to ensure new tokens are contracts
            if (token.code.length == 0) {
                revert errTokenNotContract();
            }

            exchange = payable(LibClone.clone(_exchangeImplementation, abi.encodePacked(address(token))));
            YulExchange(exchange).initialize();

            unchecked {
                // overflow is virtually impossible, inline increment and assignation for gas saving
                getTokenWithId[++tokenCount] = token;
            }

            getExchange[token] = exchange;
            emit NewExchange(token, exchange);
        }
    }
}
