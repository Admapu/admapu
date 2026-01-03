// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IIdentityRegistry {
    function isVerifiedChilean(address user) external view returns (bool);
}

