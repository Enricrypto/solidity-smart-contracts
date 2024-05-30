// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    event logAddress(address);

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        emit logAddress(msg.sender);
        number++;
    }
}
