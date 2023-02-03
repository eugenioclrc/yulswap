
# Uniswap, Solswap, Yulswap rewrite of UniswapV1 in a modern solidity with multiple gas optimizations

A clone of Uniswap smart contracts build in educational purposes and preparations to a hackaton were i aim to build UniswapV1 in Huff.




## Lessons Learned

Building an AMM might be difficult because there are numerous paint points. It can be difficult and tricky to optimize.
For me, the important trick is to imagine a simple AMM MVP with these basic operations.

- Create a pair (only supporting ETH - token)
- Add liquidity
- Remove liquidity
- Liquidity is represented by a ERC20 token
- Swap from ETH to token
- Swap from token to ETH
- Swap from token to token



## Optimizations

For optimize it i will use foundry and a base template, so i will run the same test on all the versions.

1) Uniswap V1 deploy the same bytecode on etherscan [0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95](https://etherscan.io/address/0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95#code)
2) Solswap V1 a simple Uniswap in modern solidity
3) Solswap-clones V1 a simple Uniswap in modern solidity, that uses clones for deploy new tokens pairs
4) Yulswap a simple Uniswap partially written in `yul`


### Create New Token LP

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  228017     |  0%|
| Solswap     | 2305187     |  +910% (bad)  |
| Solswap-clones| 204426     |  **-10%** (good)|


### Add liquidity

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  99733     |  |
| Solswap     | 95695     |   |
| Solswap-clones| 100465     | |


### Remove liquidity

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  18624     |   |
| Solswap     | 19813     |    |
| Solswap-clones| 20098     |  |

### Swap token to ETH

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  17532     |         |
| Solswap     |  17855     |         |
| Solswap-clones| 18173     |        |


### Swap ETH to token


| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  16871     |         |
| Solswap     |  17266     |         |
| Solswap-clones| 17536     |        |


### Swap token to token

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  28759     |         |
| Solswap     |  26482     |         |
| Solswap-clones| 27016     |        |


### TLDR;

Lets make a gas budget, lets imagene 1 create pair, 5 add liquidity, 5 remove liquidity and 30 swaps (per each type of swap);

| Codebase    | Total Gas spend   |  detal gas Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  1451422     |      0   |
| Solswap     |  3498757     |     2047335    |
| Solswap-clones| 1434491     |    **−16931**    |

- UniV1:            1451422 gas units
- Solswap:          3498757 gas units
- Solswap-clones:   1434491 gas units

So far not impressive but what an average gas budget based on a posible escenario we got some gas savings vs the original version.
## Roadmap

- [x]  Base testing
- [ ]  Testing edge escenarios with weird tokens
- [ ]  Exahustive testing with fuzzing
- [x]  Uniswap V1 as benchmark
- [x]  Solswap V1 simple
- [x]  Solswap V1 with clones
- [ ]  Yulswap V1
- [ ]  Huffswap V1 (aim for denver hackaton)