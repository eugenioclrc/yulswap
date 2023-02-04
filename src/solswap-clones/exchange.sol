// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IExchange} from "src/interfaces/ExpectedInterfaceExchange.sol";

import {SolFactoryClones} from "./factory.sol";

contract SolExchange is ERC20 {
    // Address of ERC20 token sold on this exchange
    address public tokenAddress;
    // Address of Solswap Factory
    address public immutable factoryAddress;

    // to track implementation
    address private immutable self;

    uint8 private _initialized = 1;

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

    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }

    receive() external payable {}

    constructor() ERC20("Clone Iplementation", "IMPL-V1", 18) {
        factoryAddress = msg.sender;
        self = address(this);
        locked = 2;
    }

    function initialize(address token) external {
        require(_initialized == 0, "contract has been initialized");
        require(self != address(this), "factory initializer disabled");
        _initialized = 1;
        tokenAddress = token;
        name = "Uniswap V1";
        symbol = "UNI-V1";
        locked = 1;
    }

    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
        external
        payable
        nonReentrant
        returns (uint256 liquidity_minted)
    {
        if (deadline <= block.timestamp) {
            revert ErrDeadlineExpired(deadline);
        }

        if (max_tokens == 0) {
            revert ErrZero();
        }

        if (msg.value == 0) {
            revert ErrZero();
        }

        uint256 total_liquidity = totalSupply;

        uint256 token_amount;
        if (total_liquidity > 0) {
            if (min_liquidity == 0) {
                revert ErrZero();
            }

            uint256 eth_reserve = address(this).balance - msg.value;

            uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));
            unchecked {
                token_amount = msg.value * token_reserve / eth_reserve + 1;
                liquidity_minted = msg.value * total_liquidity / eth_reserve;
            }
            if (max_tokens < token_amount) {
                revert ErrMaxTokens(max_tokens);
            }
            if (liquidity_minted < min_liquidity) {
                revert ErrMinLiquidity(min_liquidity);
            }
        } else {
            token_amount = max_tokens;
            liquidity_minted = msg.value;
        }

        _mint(msg.sender, liquidity_minted);
        SafeTransferLib.safeTransferFrom(tokenAddress, msg.sender, address(this), token_amount);

        emit AddLiquidity(msg.sender, msg.value, token_amount);
    }

    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline)
        external
        nonReentrant
        returns (uint256 eth_amount, uint256 token_amount)
    {
        if (amount == 0) {
            revert ErrZero();
        }
        if (deadline <= block.timestamp) {
            revert ErrDeadlineExpired(deadline);
        }
        if (min_eth == 0) {
            revert ErrZero();
        }
        if (min_tokens == 0) {
            revert ErrZero();
        }

        uint256 total_liquidity = totalSupply;
        if (total_liquidity == 0) {
            revert ErrZero();
        }
        uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));
        unchecked {
            eth_amount = amount * address(this).balance / total_liquidity;
            token_amount = amount * token_reserve / total_liquidity;
        }
        if (eth_amount < min_eth) {
            revert ErrBurnEthAmount(eth_amount);
        }
        if (token_amount < min_tokens) {
            revert ErrBurnTokenAmount(token_amount);
        }
        _burn(msg.sender, amount);
        SafeTransferLib.safeTransfer(tokenAddress, msg.sender, token_amount);
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
        if (deadline < block.timestamp) {
            revert ErrDeadlineExpired(deadline);
        }
        if (msg.value == 0) {
            revert ErrZero();
        }
        if (min_tokens == 0) {
            revert ErrZero();
        }

        uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));
        tokens_bought = getInputPrice(msg.value, address(this).balance - msg.value, token_reserve);
        if (tokens_bought < min_tokens) {
            revert ErrTokensOutpur(min_tokens);
        }

        SafeTransferLib.safeTransfer(tokenAddress, recipient, tokens_bought);

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
        if (deadline <= block.timestamp) {
            revert ErrDeadlineExpired(deadline);
        }

        if (tokens_sold == 0) {
            revert ErrZero();
        }
        if (min_eth == 0) {
            revert ErrZero();
        }

        uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));

        eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
        if (eth_bought < min_eth) {
            revert ErrEthOutput(min_eth);
        }
        SafeTransferLib.safeTransferFrom(tokenAddress, msg.sender, address(this), tokens_sold);
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
        address payable exchange_addr = SolFactoryClones(factoryAddress).getExchange(token_addr);
        if (deadline <= block.timestamp) {
            revert ErrDeadlineExpired(deadline);
        }

        if (tokens_sold == 0) {
            revert ErrZero();
        }
        if (min_tokens_bought == 0) {
            revert ErrZero();
        }
        if (min_eth_bought == 0) {
            revert ErrZero();
        }

        require(exchange_addr != address(this) && exchange_addr != address(0));

        uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));
        uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
        require(eth_bought >= min_eth_bought, "eth less than expextec");

        SafeTransferLib.safeTransferFrom(tokenAddress, msg.sender, address(this), tokens_sold);

        tokens_bought =
            IExchange(exchange_addr).ethToTokenSwapInput{value: eth_bought}(min_tokens_bought, deadline, msg.sender);

        emit EthPurchase(msg.sender, msg.sender, tokens_sold, eth_bought);
    }

    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought) {
        if (eth_sold == 0) {
            revert ErrZero();
        }
        uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));

        if (token_reserve == 0) {
            revert ErrZero();
        }
        return getInputPrice(eth_sold, address(this).balance, token_reserve);
    }

    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought) {
        if (tokens_sold == 0) {
            revert ErrZero();
        }
        uint256 token_reserve = ERC20(tokenAddress).balanceOf(address(this));
        return getInputPrice(tokens_sold, token_reserve, address(this).balance);
    }

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 input_amount_with_fee = input_amount * 997;
            uint256 numerator = input_amount_with_fee * output_reserve;
            uint256 denominator = (input_reserve * 1000) + input_amount_with_fee;
            return numerator / denominator;
        }
    }
}
