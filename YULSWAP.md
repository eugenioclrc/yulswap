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

