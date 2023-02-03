// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SolExchange} from "./exchange.sol";

contract SolFactory {
    uint256 public tokenCount;
    mapping(address => address payable) private _tokenToExchange;
    mapping(address => address) private _exchangeToToken;
    mapping(uint256 => address) private _idToToken;

    // address private immutable _exchangeImplementation;

    event NewExchange(address indexed token, address indexed exchange);

    constructor() {
        // _exchangeImplementation = address(new SolExchange());
    }

    function createExchange(address token) external returns (address payable exchange) {
        exchange = payable(_tokenToExchange[token]);
        if (exchange == address(0)) {
            exchange = payable(address(new SolExchange(token)));
            
            unchecked {
                // overflow is virtually impossible, inline increment and assignation for gas saving
                _idToToken[++tokenCount] = token;
            }

            _tokenToExchange[token] = exchange;
            _exchangeToToken[exchange] = token;
            emit NewExchange(token, exchange);
        }
    }

    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address payable exchange) {
        return _tokenToExchange[token];
    }

    function getToken(address exchange) external view returns (address token) {
        return _exchangeToToken[exchange];
    }

    function getTokenWithId(uint256 tokenId) external view returns (address token) {
        return _idToToken[tokenId];
    }
}
