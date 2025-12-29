// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MockIdentityRegistry
 * @notice Registro mock de atributos de identidad para PoC.
 *         Reemplazable más adelante por integración real (ZKPassport / issuer).
 */
contract MockIdentityRegistry is AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct Identity {
        bool verifiedChilean;
        bool senior;
        bool chronicMeds;
    }

    mapping(address => Identity) private _identities;

    event IdentityUpdated(
        address indexed user, bool verifiedChilean, bool senior, bool chronicMeds, address indexed updatedBy
    );

    constructor(address admin) {
        require(admin != address(0), "admin=0");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
    }

    // --------- Read API ---------
    function isVerifiedChilean(address user) external view returns (bool) {
        return _identities[user].verifiedChilean;
    }

    function isSenior(address user) external view returns (bool) {
        return _identities[user].senior;
    }

    function hasChronicMeds(address user) external view returns (bool) {
        return _identities[user].chronicMeds;
    }

    function getIdentity(address user) external view returns (Identity memory) {
        return _identities[user];
    }

    // --------- Write API (mock issuer) ---------
    /**
     * @notice Setea todos los flags de una persona en una sola operación.
     */
    function setIdentity(address user, bool verifiedChilean, bool senior, bool chronicMeds)
        external
        onlyRole(ISSUER_ROLE)
    {
        _setIdentity(user, verifiedChilean, senior, chronicMeds);
    }

    /**
     * @notice Helpers para setear campos individuales (más cómodo para tests/manual).
     */
    function setVerifiedChilean(address user, bool value) external onlyRole(ISSUER_ROLE) {
        Identity memory id = _identities[user];
        _setIdentity(user, value, id.senior, id.chronicMeds);
    }

    function setSenior(address user, bool value) external onlyRole(ISSUER_ROLE) {
        Identity memory id = _identities[user];
        _setIdentity(user, id.verifiedChilean, value, id.chronicMeds);
    }

    function setChronicMeds(address user, bool value) external onlyRole(ISSUER_ROLE) {
        Identity memory id = _identities[user];
        _setIdentity(user, id.verifiedChilean, id.senior, value);
    }

    // --------- Internal ---------

    function _setIdentity(address user, bool verifiedChilean, bool senior, bool chronicMeds) internal {
        require(user != address(0), "user=0");

        _identities[user] = Identity({verifiedChilean: verifiedChilean, senior: senior, chronicMeds: chronicMeds});

        emit IdentityUpdated(user, verifiedChilean, senior, chronicMeds, msg.sender);
    }
}
