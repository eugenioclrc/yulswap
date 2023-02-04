// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {YulExchange} from "./exchange.sol";
import {LibClone} from "solady/utils/LibClone.sol";

contract YulFactory {
    // from https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args/blob/main/src/ExampleCloneFactory.sol
    using LibClone for address;

    uint256 public tokenCount;
    mapping(address => address payable) private _tokenToExchange;
    mapping(address => address) private _exchangeToToken;
    mapping(uint256 => address) private _idToToken;

    address private immutable _exchangeImplementation;

    event NewExchange(address indexed token, address indexed exchange);

    constructor() {
        _exchangeImplementation = address(new YulExchange());
    }

    function createExchange(address token) external returns (address payable exchange) {
        exchange = payable(_tokenToExchange[token]);
        if (exchange == address(0)) {
            // add check to ensure new tokens are contracts
            require(token.code.length > 0, "token not a contract");

            exchange = payable(_exchangeImplementation.clone(abi.encodePacked(address(token))));
            YulExchange(exchange).initialize();

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
