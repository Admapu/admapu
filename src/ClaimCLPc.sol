// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

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
contract ClaimCLPc {
    // --- Config ---
    ICLPcMinter public immutable TOKEN;
    IIdentityRegistryView public immutable IDENTITY_REGISTRY;
    uint256 public immutable CLAIM_AMOUNT;

    // --- Admin simple ---
    address public admin;
    bool public paused;
    address public trustedForwarder;

    // --- State ---
    mapping(address => bool) public claimed;

    // --- Events ---
    event Claimed(address indexed user, uint256 amount);
    event Paused(bool paused);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event TrustedForwarderUpdated(address indexed oldForwarder, address indexed newForwarder);

    // --- Errors ---
    error NotAdmin();
    error PausedError();
    error NotVerified(address user);
    error AlreadyClaimed(address user);
    error ZeroAddress();
    error ZeroAmount();

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() internal view {
        if (_msgSender() != admin) revert NotAdmin();
    }

    constructor(address _token, address _identityRegistry, uint256 _claimAmount, address _admin) {
        if (_token == address(0) || _identityRegistry == address(0) || _admin == address(0)) revert ZeroAddress();
        if (_claimAmount == 0) revert ZeroAmount();

        TOKEN = ICLPcMinter(_token);
        IDENTITY_REGISTRY = IIdentityRegistryView(_identityRegistry);
        CLAIM_AMOUNT = _claimAmount;
        admin = _admin;
    }

    function setPaused(bool _paused) external onlyAdmin {
        paused = _paused;
        emit Paused(_paused);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @notice Configura el trusted forwarder para meta-transacciones ERC-2771.
     * @dev Solo admin. Usar address(0) para deshabilitar meta-txs.
     */
    function setTrustedForwarder(address _trustedForwarder) external onlyAdmin {
        emit TrustedForwarderUpdated(trustedForwarder, _trustedForwarder);
        trustedForwarder = _trustedForwarder;
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
    function claim() external {
        address sender = _msgSender();

        if (paused) revert PausedError();
        if (claimed[sender]) revert AlreadyClaimed(sender);
        if (!IDENTITY_REGISTRY.isVerifiedChilean(sender)) revert NotVerified(sender);

        claimed[sender] = true;

        TOKEN.mint(sender, CLAIM_AMOUNT);

        emit Claimed(sender, CLAIM_AMOUNT);
    }

    /**
     * @dev Devuelve el sender original si la llamada llega desde trustedForwarder.
     */
    function _msgSender() internal view returns (address sender) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
            assembly ("memory-safe") {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
}
