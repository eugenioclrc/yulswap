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