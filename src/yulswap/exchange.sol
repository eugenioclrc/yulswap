// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC20} from "./yulERC20.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {Clone} from "solady/utils/Clone.sol";

import {IExchange} from "src/interfaces/ExpectedInterfaceExchange.sol";

import {YulFactory} from "./factory.sol";

// custom reentrancy guard
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract YulExchange is ERC20, Clone, ReentrancyGuard {
    // Address of ERC20 token sold on this exchange
    // from https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args/blob/main/src/ExampleCloneFactory.sol
    // address public tokenAddress;
    // Use clone with immutable hack from solady

    // Address of Solswap Factory
    address public immutable factoryAddress;

    // events
    // drop the indexed keyword on eth_sold and tokens_bought to save gas
    event TokenPurchase(address indexed buyer, address recipient, uint256 eth_sold, uint256 tokens_bought);
    event AddLiquidity(address indexed provider, uint256 eth_amount, uint256 token_amount);
    event RemoveLiquidity(address indexed provider, uint256 eth_amount, uint256 token_amount);
    event EthPurchase(address indexed buyer, address recipient, uint256 tokens_sold, uint256 eth_bought);

    // erros
    error ErrDeadlineExpired(uint256 deadline);
    error ErrZero();
    error ErrMaxTokens(uint256 max_tokens);
    error ErrMinLiquidity(uint256 min_liquidity);
    error ErrBurnEthAmount(uint256 eth_amount);
    error ErrBurnTokenAmount(uint256 token_amount);
    error ErrTokensOutpur(uint256 min_tokens);
    error ErrEthOutput(uint256 min_eth);
    error ErrOnlyFactory();
    error ErrSameToken();
    error ErrLessEthThanExpected();

    constructor() ERC20() {
        factoryAddress = msg.sender;
    }

    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
        external
        payable
        nonReentrant
        returns (uint256 liquidity_minted)
    {
        if (deadline <= block.timestamp) revert ErrDeadlineExpired(deadline);
        if (max_tokens == 0) revert ErrZero();
        if (msg.value == 0) revert ErrZero();

        uint256 total_liquidity = totalSupply;

        uint256 token_amount;

        address _tokenAddress = _getArgAddress(0);

        if (total_liquidity > 0) {
            if (min_liquidity == 0) revert ErrZero();

            uint256 eth_reserve;

            uint256 token_reserve = tokenBalanceOf(_tokenAddress, address(this));
            assembly {
                // current ether (include msg.value) - msg.value = balance before tx
                eth_reserve := sub(selfbalance(), callvalue())
                token_amount := add(div(mul(callvalue(), token_reserve), eth_reserve), 1)
                liquidity_minted := div(mul(callvalue(), total_liquidity), eth_reserve)
            }
            if (max_tokens < token_amount) revert ErrMaxTokens(max_tokens);
            if (liquidity_minted < min_liquidity) revert ErrMinLiquidity(min_liquidity);
        } else {
            token_amount = max_tokens;
            liquidity_minted = msg.value;
        }

        _mint(msg.sender, liquidity_minted);
        SafeTransferLib.safeTransferFrom(_tokenAddress, msg.sender, address(this), token_amount);

        emit AddLiquidity(msg.sender, msg.value, token_amount);
    }

    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline)
        external
        nonReentrant
        returns (uint256 eth_amount, uint256 token_amount)
    {
        if (amount == 0) revert ErrZero();
        if (deadline <= block.timestamp) revert ErrDeadlineExpired(deadline);
        if (min_eth == 0) revert ErrZero();
        if (min_tokens == 0) revert ErrZero();

        uint256 total_liquidity = totalSupply;
        if (total_liquidity == 0) revert ErrZero();

        address _tokenAddress = _getArgAddress(0);
        uint256 token_reserve = tokenBalanceOf(_tokenAddress, address(this));
        assembly {
            eth_amount := div(mul(amount, selfbalance()), total_liquidity)
            token_amount := div(mul(amount, token_reserve), total_liquidity)
        }

        if (eth_amount < min_eth) revert ErrBurnEthAmount(eth_amount);
        if (token_amount < min_tokens) revert ErrBurnTokenAmount(token_amount);

        _burn(msg.sender, amount);
        SafeTransferLib.safeTransfer(_tokenAddress, msg.sender, token_amount);
        SafeTransferLib.safeTransferETH(msg.sender, eth_amount);
        emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
    }

    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought)
    {
        return ethToTokenSwapInput(min_tokens, deadline, msg.sender);
    }

    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline, address recipient)
        public
        payable
        nonReentrant
        returns (uint256 tokens_bought)
    {
        if (deadline < block.timestamp) revert ErrDeadlineExpired(deadline);
        if (msg.value == 0) revert ErrZero();
        if (min_tokens == 0) revert ErrZero();
        
        address _tokenAddress = _getArgAddress(0);
        uint256 token_reserve = tokenBalanceOf(_tokenAddress, address(this));
        uint256 prevEthBalance;
        assembly {
            prevEthBalance := sub(selfbalance(), callvalue())
        }
        tokens_bought = getInputPrice(msg.value, prevEthBalance, token_reserve);
        if (tokens_bought < min_tokens) revert ErrTokensOutpur(min_tokens);

        SafeTransferLib.safeTransfer(_tokenAddress, recipient, tokens_bought);

        emit TokenPurchase(msg.sender, recipient, msg.value, tokens_bought);
    }

    // Trade ERC20 to ETH

    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline)
        external
        returns (uint256 tokens_bought)
    {
        return tokenToEthSwapInput(tokens_sold, min_eth, deadline, msg.sender);
    }

    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient)
        public
        nonReentrant
        returns (uint256 eth_bought)
    {
        if (deadline <= block.timestamp) revert ErrDeadlineExpired(deadline);
        if (tokens_sold == 0) revert ErrZero();
        if (min_eth == 0) revert ErrZero();

        address _tokenAddress = _getArgAddress(0);
        uint256 token_reserve = tokenBalanceOf(_tokenAddress, address(this));

        uint256 _balance;
        assembly {
            _balance := selfbalance()
        }

        eth_bought = getInputPrice(tokens_sold, token_reserve, _balance);
        if (eth_bought < min_eth) revert ErrEthOutput(min_eth);

        SafeTransferLib.safeTransferFrom(_tokenAddress, msg.sender, address(this), tokens_sold);
        SafeTransferLib.safeTransferETH(recipient, eth_bought);

        emit EthPurchase(msg.sender, recipient, tokens_sold, eth_bought);
    }

    /// @dev User specifies exact input and minimum output. Convert Tokens  to Tokens token_addr.
    /// @param tokens_sold Amount of Tokens sold.
    /// @param min_tokens_bought Minimum Tokens (token_addr) purchased.
    /// @param min_eth_bought Minimum ETH purchased as intermediary.
    /// @param deadline Time after which this transaction can no longer be executed.
    /// @param token_addr The address of the token being purchased.
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external nonReentrant returns (uint256 tokens_bought) {
        if (deadline < block.timestamp) revert ErrDeadlineExpired(deadline);
        if (tokens_sold == 0) revert ErrZero();
        if (min_tokens_bought == 0) revert ErrZero();
        if (min_eth_bought == 0) revert ErrZero();
        
        address exchange_addr = YulFactory(factoryAddress).getExchange(token_addr);

        if (exchange_addr == address(this)) revert ErrSameToken();
        if (exchange_addr == address(0)) revert ErrZero();
        
        address _tokenAddress = _getArgAddress(0);
        uint256 token_reserve = tokenBalanceOf(_tokenAddress, address(this));

        uint256 _balance;
        assembly {
            _balance := selfbalance()
        }

        uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, _balance);
        if (eth_bought < min_eth_bought) revert ErrLessEthThanExpected();

        SafeTransferLib.safeTransferFrom(_tokenAddress, msg.sender, address(this), tokens_sold);

        tokens_bought =
            IExchange(exchange_addr).ethToTokenSwapInput{value: eth_bought}(min_tokens_bought, deadline, msg.sender);

        emit EthPurchase(msg.sender, msg.sender, tokens_sold, eth_bought);
    }

    function tokenAddress() external pure returns (address) {
        return _getArgAddress(0);
    }

    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought) {
        if (eth_sold == 0) {
            revert ErrZero();
        }
        uint256 token_reserve = tokenBalanceOf(_getArgAddress(0), address(this));

        if (token_reserve == 0) revert ErrZero();

        uint256 _balance;
        assembly {
            _balance := selfbalance()
        }

        return getInputPrice(eth_sold, _balance, token_reserve);
    }

    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought) {
        if (tokens_sold == 0) {
            revert ErrZero();
        }
        uint256 token_reserve = tokenBalanceOf(_getArgAddress(0), address(this));
        uint256 _balance;
        assembly {
            _balance := selfbalance()
        }

        return getInputPrice(tokens_sold, token_reserve, _balance);
    }

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)
        internal
        pure
        returns (uint256 output_amount)
    {
        assembly {
            let input_amount_with_fee := mul(input_amount, 997)
            let numerator := mul(input_amount_with_fee, output_reserve)
            let denominator := add(mul(input_reserve, 1000), input_amount_with_fee)
            output_amount := div(numerator, denominator)
        }
    }

    // gas golfing internal function

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function tokenBalanceOf(address _token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, account) // Store the `account` argument.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), _token, 0x1c, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}
