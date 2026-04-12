// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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
contract ClaimCLPc is Ownable2Step, Pausable, ReentrancyGuard {
    // --- Config ---
    ICLPcMinter public immutable TOKEN;
    IIdentityRegistryView public immutable IDENTITY_REGISTRY;
    uint256 public immutable CLAIM_AMOUNT;

    uint256 public constant TRUSTED_FORWARDER_UPDATE_DELAY = 2 days;

    address public trustedForwarder;
    address public pendingTrustedForwarder;
    uint256 public pendingTrustedForwarderEta;

    // --- State ---
    mapping(address => bool) public claimed;

    // --- Events ---
    event Claimed(address indexed user, uint256 amount);
    event ClaimPaused(bool paused);
    event TrustedForwarderUpdated(address indexed oldForwarder, address indexed newForwarder);
    event TrustedForwarderUpdateScheduled(address indexed newForwarder, uint256 executeAfter);
    event TrustedForwarderUpdateCancelled();

    // --- Errors ---
    error NotVerified(address user);
    error AlreadyClaimed(address user);
    error ZeroAddress();
    error ZeroAmount();
    error TrustedForwarderUpdateNotReady(uint256 executeAfter);
    error NoPendingTrustedForwarderUpdate();

    constructor(address _token, address _identityRegistry, uint256 _claimAmount, address _admin) Ownable(_admin) {
        if (_token == address(0) || _identityRegistry == address(0) || _admin == address(0)) revert ZeroAddress();
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
     * @notice Configura el trusted forwarder para meta-transacciones ERC-2771.
     * @dev Solo admin. Usar address(0) para deshabilitar meta-txs.
     */
    function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
        pendingTrustedForwarder = _trustedForwarder;
        pendingTrustedForwarderEta = block.timestamp + TRUSTED_FORWARDER_UPDATE_DELAY;

        emit TrustedForwarderUpdateScheduled(_trustedForwarder, pendingTrustedForwarderEta);
    }

    /**
     * @notice Ejecuta el cambio de trusted forwarder previamente agendado.
     * @dev Solo owner, luego de cumplido el delay.
     */
    function executeTrustedForwarderUpdate() external onlyOwner {
        address _newForwarder = pendingTrustedForwarder;
        uint256 eta = pendingTrustedForwarderEta;

        if (_newForwarder == address(0) && eta == 0) revert NoPendingTrustedForwarderUpdate();
        if (block.timestamp < eta) revert TrustedForwarderUpdateNotReady(eta);

        address oldForwarder = trustedForwarder;
        trustedForwarder = _newForwarder;

        pendingTrustedForwarder = address(0);
        pendingTrustedForwarderEta = 0;

        emit TrustedForwarderUpdated(oldForwarder, _newForwarder);
    }

    /**
     * @notice Cancela un cambio de trusted forwarder pendiente.
     * @dev Solo owner.
     */
    function cancelTrustedForwarderUpdate() external onlyOwner {
        if (pendingTrustedForwarder == address(0) && pendingTrustedForwarderEta == 0) {
            revert NoPendingTrustedForwarderUpdate();
        }

        pendingTrustedForwarder = address(0);
        pendingTrustedForwarderEta = 0;

        emit TrustedForwarderUpdateCancelled();
    }

    /**
     * @notice Verifica si una dirección es el trusted forwarder actual.
     */
    function isTrustedForwarder(address forwarder) external view returns (bool) {
        return forwarder == trustedForwarder;
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
     * @dev Devuelve el sender original si la llamada llega desde trustedForwarder.
     */
    function _msgSender() internal view virtual override returns (address sender) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
            assembly ("memory-safe") {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
}
