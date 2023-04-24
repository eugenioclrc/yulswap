// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract ReentrancyGuard {
    error errNonReentrant();
    // by default, start locked

    uint256 private locked = 2;

    modifier nonReentrant() virtual {
        if (locked != 1) {
            revert errNonReentrant();
        }

        locked = 2;

        _;

        locked = 1;
    
    }

    function _unlockReentrancy() internal {
        locked = 1;
    }
}
