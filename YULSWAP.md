# Optimizations tricks with gasdiff

Im gonna add each optimization that i made on the yul rewrite, this is probably gonna be a long file..

From start im gonna just use the "Solswap-clones" version and start rewrit thigs in yul.

## Base snap
`forge snapshot --match-contract YulswapTest --snap yul0-base`

```
Running 9 tests for test/base.YulswapV1.t.sol:YulswapTest
[PASS] testAddLiquidity() (gas: 152342)
[PASS] testCreateExchange() (gas: 234689)
[PASS] testExchangeMetadata() (gas: 18030)
[PASS] testRemoveLiquidity() (gas: 101972)
[PASS] testSwapEthToken() (gas: 147429)
[PASS] testSwapMultipleTimes() (gas: 6637055)
[PASS] testSwapTokenEth() (gas: 141487)
[PASS] testSwapTokenToToken() (gas: 456251)
[PASS] testSwapTokenToTokenMultipleTimes() (gas: 8096012)
```

## Optimization 1, use a yul function for get the balance;

[code detail change](https://github.com/eugenioclrc/yulswap/commit/19d193cd5967d659babd14b4480cd98273a6bb26)
```solidity
function tokenBalanceOf(address account) internal view returns (uint256 amount) {
    address _token = tokenAddress;
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
```

### Gas diff

```sh
forge snapshot --match-contract YulswapTest --diff yul0-base
testSwapTokenToToken() (gas: -248 (-0.054%)) 
testRemoveLiquidity() (gas: -100 (-0.098%)) 
testSwapMultipleTimes() (gas: -19840 (-0.299%)) 
testSwapEthToken() (gas: -496 (-0.336%)) 
testSwapTokenEth() (gas: -496 (-0.351%)) 
testSwapTokenToTokenMultipleTimes() (gas: -39779 (-0.491%)) 
Overall gas change: -60959 (-1.630%)
```
Nice! 1% less, now lets save this as a snapshot

then take a new snap;
`forge snapshot --match-contract YulswapTest --snap yul1-base`


## Optimization 2, lets rewrite `getInputPrice`

[getInputPrice to yul](https://github.com/eugenioclrc/yulswap/commit/4e28b85e25d99230fd6309979b111d12bc7c7e10)

```solidity
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
```

### Gas diff

```
forge snapshot --match-contract YulswapTest --diff yul1-base
testSwapTokenToToken() (gas: -137 (-0.030%)) 
testSwapMultipleTimes() (gas: -10960 (-0.166%)) 
testSwapEthToken() (gas: -250 (-0.170%)) 
testSwapTokenEth() (gas: -314 (-0.223%)) 
testSwapTokenToTokenMultipleTimes() (gas: -21966 (-0.273%)) 
Overall gas change: -33627 (-0.861%)
```

Ok not 1%, but it works.

Lets take a new snap;
`forge snapshot --match-contract YulswapTest --snap yul2-base`

### Math to yul

[Math operations in yul](https://github.com/eugenioclrc/yulswap/commit/70f7411fbb1aa0f76ae25f61745687165ea0eb31)


### Gas diff

```
forge snapshot --match-contract YulswapTest --diff yul2-base
testRemoveLiquidity() (gas: -27 (-0.027%)) 
Overall gas change: -27 (-0.027%)
```

A bit disappointed, but it works.

New snapshot;
`forge snapshot --match-contract YulswapTest --snap yul3-base`


### Add extra checks to ensure token is a contract +refactor

[`89555d1`](https://github.com/eugenioclrc/yulswap/commit/89555d1d839fcea9aafa65addac67fe272b20d58)

```
forge snapshot --match-contract YulswapTest --diff yul3-base

testSwapTokenToTokenMultipleTimes() (gas: -16 (-0.000%)) 
testSwapTokenToToken() (gas: -20 (-0.004%)) 
testCreateExchange() (gas: 2480 (1.057%)) 
Overall gas change: 2444 (1.052%)
```

Gas increased, but necessary checks...

New snap
`forge snapshot --match-contract YulswapTest --snap yul4-base`

### Add more yul stuff and refactor removing unnesesary variable

[`f2910c8`](https://github.com/eugenioclrc/yulswap/commit/f2910c89a7aafd0c490cd6636777d1f5efce15f9)

```
forge snapshot --match-contract YulswapTest --diff yul4-base
testAddLiquidity() (gas: 1 (0.001%)) 
testSwapTokenEth() (gas: 1 (0.001%)) 
testRemoveLiquidity() (gas: 1 (0.001%)) 
testCreateExchange() (gas: -19 (-0.008%)) 
testSwapTokenToToken() (gas: -104 (-0.023%)) 
testSwapMultipleTimes() (gas: -5359 (-0.081%)) 
testSwapEthToken() (gas: -147 (-0.100%)) 
testSwapTokenToTokenMultipleTimes() (gas: -13987 (-0.174%)) 
Overall gas change: -19613 (-0.384%)
```

New snap
`forge snapshot --match-contract YulswapTest --snap yul5-base`

### Refactor cache `tokenAddress` to avoid multiple `SLOAD`
  
[`87ff058`](https://github.com/eugenioclrc/yulswap/commit/87ff058000ad6486f25818996b153e567a07a8cb)

```
forge snapshot --match-contract YulswapTest --diff yul5-base
testAddLiquidity() (gas: 8 (0.005%)) 
testSwapTokenToToken() (gas: -213 (-0.047%)) 
testRemoveLiquidity() (gas: -86 (-0.084%)) 
testSwapEthToken() (gas: -129 (-0.088%)) 
testSwapTokenEth() (gas: -129 (-0.092%)) 
testSwapMultipleTimes() (gas: -18554 (-0.281%)) 
testSwapTokenToTokenMultipleTimes() (gas: -36720 (-0.458%)) 
Overall gas change: -55823 (-1.045%)
```

Good! it could be better if `addressToken` is an `immutable` but since its a proxy implementation its not possible, so caching its a must.

New snap
`forge snapshot --match-contract YulswapTest --snap yul6-base`

### Clones with immutables via solady

[`0355252`](https://github.com/eugenioclrc/yulswap/commit/0355252141f36610cbef39c70e330c29cb7073f9)

```
forge snapshot --match-contract YulswapTest --diff yul6-base

testSwapMultipleTimes() (gas: -11778 (-0.179%)) 
testSwapTokenToTokenMultipleTimes() (gas: -17191 (-0.215%)) 
testExchangeMetadata() (gas: 118 (0.654%)) 
testAddLiquidity() (gas: -1895 (-1.244%)) 
testSwapEthToken() (gas: -2179 (-1.488%)) 
testSwapTokenEth() (gas: -2265 (-1.612%)) 
testRemoveLiquidity() (gas: -1705 (-1.676%)) 
testSwapTokenToToken() (gas: -9108 (-1.999%)) 
testCreateExchange() (gas: -7012 (-2.957%)) 
Overall gas change: -53015 (-10.715%)
```

**-10.71%** ultra sweet!!!

New snap
`forge snapshot --match-contract YulswapTest --snap yul7-base`

### Add constant to name and string in a custom ERC20

```
forge snapshot --match-contract YulswapTest --diff yul7-base
Running 10 tests for test/base.YulswapV1.t.sol:YulswapTest
[PASS] testAddLiquidity() (gas: 150459)
[PASS] testCreateExchange() (gas: 185039)
[PASS] testExchangeMetadata() (gas: 12764)
[PASS] testProxyHack() (gas: 169652)
[PASS] testRemoveLiquidity() (gas: 100055)
[PASS] testSwapEthToken() (gas: 144231)
[PASS] testSwapMultipleTimes() (gas: 6570566)
[PASS] testSwapTokenEth() (gas: 138287)
[PASS] testSwapTokenToToken() (gas: 401328)
[PASS] testSwapTokenToTokenMultipleTimes() (gas: 7930279)
Test result: ok. 10 passed; 0 failed; finished in 14.84ms
testRemoveLiquidity() (gas: 0 (0.000%)) 
testSwapMultipleTimes() (gas: 2 (0.000%)) 
testAddLiquidity() (gas: 3 (0.002%)) 
testSwapEthToken() (gas: 3 (0.002%)) 
testSwapTokenEth() (gas: 3 (0.002%)) 
testSwapTokenToTokenMultipleTimes() (gas: -36074 (-0.453%)) 
testSwapTokenToToken() (gas: -45093 (-10.101%)) 
testCreateExchange() (gas: -45099 (-19.597%)) 
testProxyHack() (gas: -45099 (-21.001%)) 
testExchangeMetadata() (gas: -5384 (-29.667%)) 
Overall gas change: -176738 (-1.106%)
```

** losts on savings while creating a new exchange **

New snap
`forge snapshot --match-contract YulswapTest --snap yul8-base`
