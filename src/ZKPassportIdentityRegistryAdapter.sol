// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IIdentityRegistry} from "./IIdentityRegistry.sol";
import {IZKPassportVerifier} from "./IZKPassportVerifier.sol";

/**
 * @title ZKPassportIdentityRegistryAdapter
 * @notice Adapter para exponer un verificador ZKPassport como IIdentityRegistry.
 * @dev Permite que CLPc use `isVerifiedChilean(address)` sobre un verifier que expone `isVerified(address)`.
 */
contract ZKPassportIdentityRegistryAdapter is IIdentityRegistry {
    IZKPassportVerifier public immutable VERIFIER;

    error ZeroAddress();

    constructor(address _verifier) {
        if (_verifier == address(0)) revert ZeroAddress();
        VERIFIER = IZKPassportVerifier(_verifier);
    }

    function isVerifiedChilean(address user) external view override returns (bool) {
        return VERIFIER.isVerified(user);
    }
}
