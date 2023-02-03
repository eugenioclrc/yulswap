
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



## Overall

For optimize it i will use foundry and a base template, so i will run the same test on all the versions.

1) Uniswap V1 deploy the same bytecode on etherscan [0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95](https://etherscan.io/address/0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95#code)
2) Solswap V1 a simple Uniswap in modern solidity
3) Solswap-clones V1 a simple Uniswap in modern solidity, that uses clones for deploy new tokens pairs
4) Yulswap a simple Uniswap partially written in `yul`


### Create New Token LP

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  228017     |  |
| Solswap     | 2305187     |    |
| Solswap-clones| 204426     |  |
| Yulswap     |   199909    |                  |


### Add liquidity

| Codebase      | Gas spend   |  Diff vs UniV1 |
| -----------   | ----------- |  -------       |
| UniV1         |  99733     |                |
| Solswap       | 95695      |                |
| Solswap-clones| 100465      |                |
| Yulswap       |   98429     |                |


### Remove liquidity


| Codebase      | Gas spend   |  Diff vs UniV1 |
| -----------   | ----------- |  -------       |
| UniV1         |  18624     |   |
| Solswap       | 19813     |    |
| Solswap-clones| 20098     |  |
| Yulswap       |   19782    |                |



### Swap token to ETH


| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  17532     |         |
| Solswap     |  17855     |         |
| Solswap-clones| 18173     |        |
| Yulswap       |   17854    |                |


### Swap ETH to token

| Codebase      | Gas spend   |  Diff vs UniV1 |
| -----------   | ----------- |  -------       |
| UniV1         |  16871     |         |
| Solswap       |  17266     |         |
| Solswap-clones|  17536     |        |
| Yulswap       |   17171    |                |

### Swap token to token

| Codebase    | Gas spend   |  Diff vs UniV1 |
| ----------- | ----------- |  -------       |
| UniV1       |  28759     |         |
| Solswap     |  26482     |         |
| Solswap-clones| 27016     |        |
| Yulswap       |   26315    |                |


### TLDR;

Lets make a gas budget, lets imagine 1 create pair, 5 add liquidity, 5 remove liquidity and 30 swaps (per each type of swap);

| Codebase      | Total Gas spend   |  detal gas Diff vs UniV1 |
| -----------   | ----------- |  -------       |
| UniV1         |     1451422 |  ---           |
| Solswap       |     3498757 |   +2047335     |
| Solswap-clones|     1434491 |   -  16931     |
| Yulswap       |     1404364 | **-  47058**   |


- UniV1:            1451422 gas units
- Solswap:          3498757 gas units
- Solswap-clones:   1434491 gas units
- [Yulswap](https://github.com/eugenioclrc/yulswap/commit/b098e97940a0cdad3c6b578cbbe973bb05174c13):          1404364 gas units (last update commit `b098e97940`) [optimization writeup](/YULSWAP.md)


So far not impressive but what an average gas budget based on a posible escenario we got some gas savings vs the original version.
## Roadmap

- [x]  Base testing
- [ ]  Testing edge escenarios with weird tokens
- [ ]  Exahustive testing with fuzzing
- [x]  Uniswap V1 as benchmark
- [x]  Solswap V1 simple
- [x]  Solswap V1 with clones
- [x]  Yulswap V1 (partially written in yul until in the benchmark i dont get any gas saving)
- [ ]  Huffswap V1 (aim for denver hackaton)