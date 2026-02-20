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

    // --- State ---
    mapping(address => bool) public claimed;

    // --- Events ---
    event Claimed(address indexed user, uint256 amount);
    event Paused(bool paused);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

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
        if (msg.sender != admin) revert NotAdmin();
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
     * @notice Reclama CLPc una sola vez (solo para usuarios verificados).
     */
    function claim() external {
        if (paused) revert PausedError();
        if (claimed[msg.sender]) revert AlreadyClaimed(msg.sender);
        if (!IDENTITY_REGISTRY.isVerifiedChilean(msg.sender)) revert NotVerified(msg.sender);

        claimed[msg.sender] = true;

        // CLPc.mint() verificará también que msg.sender esté verificado (lo está)
        TOKEN.mint(msg.sender, CLAIM_AMOUNT);

        emit Claimed(msg.sender, CLAIM_AMOUNT);
    }
}

