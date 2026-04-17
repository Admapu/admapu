// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ICLPcMinter {
    function mint(address to, uint256 amount) external;
}

interface IIdentityRegistryView {
    function isVerifiedChilean(address account) external view returns (bool);
}

/**
 * @title ClaimCLPc
 * @notice Permite a usuarios verificados reclamar un monto fijo una sola vez.
 * @dev Requiere que este contrato tenga MINTER_ROLE en CLPc y use la misma fuente de verdad de identidad que CLPc.
 */
contract ClaimCLPc is Ownable2Step, ERC2771Context, Pausable, ReentrancyGuard {
    // --- Config ---
    ICLPcMinter public immutable TOKEN;
    IIdentityRegistryView public immutable IDENTITY_REGISTRY;
    uint256 public immutable CLAIM_AMOUNT;

    // --- State ---
    mapping(address => bool) public claimed;

    // --- Events ---
    event Claimed(address indexed user, uint256 amount);
    event ClaimPaused(bool paused);

    // --- Errors ---
    error NotVerified(address user);
    error AlreadyClaimed(address user);
    error ZeroAddress();
    error ZeroAmount();

    constructor(
        address _token,
        address _identityRegistry,
        uint256 _claimAmount,
        address _admin,
        address _trustedForwarder
    ) Ownable(_admin) ERC2771Context(_trustedForwarder) {
        if (_token == address(0) || _identityRegistry == address(0) || _admin == address(0)) {
            revert ZeroAddress();
        }
        if (_claimAmount == 0) revert ZeroAmount();

        TOKEN = ICLPcMinter(_token);
        IDENTITY_REGISTRY = IIdentityRegistryView(_identityRegistry);
        CLAIM_AMOUNT = _claimAmount;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
        emit ClaimPaused(_paused);
    }

    /**
     * @notice Reclama CLPc una sola vez (solo para usuarios verificados).
     */
    function claim() external nonReentrant whenNotPaused {
        address sender = _msgSender();

        if (claimed[sender]) revert AlreadyClaimed(sender);
        if (!IDENTITY_REGISTRY.isVerifiedChilean(sender)) revert NotVerified(sender);

        claimed[sender] = true;

        TOKEN.mint(sender, CLAIM_AMOUNT);

        emit Claimed(sender, CLAIM_AMOUNT);
    }

    /**
     * @dev Resuelve el sender usando ERC2771Context cuando aplica.
     */
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    /**
     * @dev Resuelve msg.data usando ERC2771Context cuando aplica.
     */
    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    /**
     * @dev ERC2771Context define un sufijo de 20 bytes para el sender reenviado.
     */
    function _contextSuffixLength() internal view virtual override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}
