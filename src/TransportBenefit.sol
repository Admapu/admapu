// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ITransportBenefitTokenMinter {
    function mint(address to, uint256 amount) external;
}

interface ITransportBenefitRegistryView {
    function isVerifiedChilean(address account) external view returns (bool);
}

/**
 * @title TransportBenefit
 * @notice Programa de beneficio mensual para personas habilitadas en el registro de transporte escolar.
 * @dev Requiere que este contrato tenga MINTER_ROLE en CLPc.
 *      La verificación chilena viene desde el registry compartido con CLPc,
 *      pero la elegibilidad de transporte vive temporalmente en este contrato
 *      como allowlist administrada por admin para facilitar el testing.
 */
contract TransportBenefit {
    uint256 public constant PERIOD_DURATION = 30 days;

    ITransportBenefitTokenMinter public immutable TOKEN;
    ITransportBenefitRegistryView public immutable IDENTITY_REGISTRY;
    uint256 public immutable BENEFIT_AMOUNT;

    address public admin;
    bool public paused;
    address public trustedForwarder;

    mapping(address => bool) public eligibleSchoolTransport;
    mapping(address => mapping(uint256 => bool)) public claimedByPeriod;

    event Claimed(address indexed user, uint256 amount, uint256 indexed period);
    event EligibilityUpdated(address indexed user, bool eligible, address indexed updatedBy);
    event Paused(bool paused);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event TrustedForwarderUpdated(address indexed oldForwarder, address indexed newForwarder);

    error NotAdmin();
    error PausedError();
    error NotVerified(address user);
    error NotEligible(address user);
    error AlreadyClaimed(address user, uint256 period);
    error ZeroAddress();
    error ZeroAmount();

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function _onlyAdmin() internal view {
        if (_msgSender() != admin) revert NotAdmin();
    }

    constructor(address _token, address _identityRegistry, uint256 _benefitAmount, address _admin) {
        if (_token == address(0) || _identityRegistry == address(0) || _admin == address(0)) revert ZeroAddress();
        if (_benefitAmount == 0) revert ZeroAmount();

        TOKEN = ITransportBenefitTokenMinter(_token);
        IDENTITY_REGISTRY = ITransportBenefitRegistryView(_identityRegistry);
        BENEFIT_AMOUNT = _benefitAmount;
        admin = _admin;
    }

    function currentPeriod() public view returns (uint256) {
        return block.timestamp / PERIOD_DURATION;
    }

    function hasClaimedCurrentPeriod(address account) external view returns (bool) {
        return claimedByPeriod[account][currentPeriod()];
    }

    function setEligible(address account, bool eligible) external onlyAdmin {
        if (account == address(0)) revert ZeroAddress();
        eligibleSchoolTransport[account] = eligible;
        emit EligibilityUpdated(account, eligible, _msgSender());
    }

    function setEligibleBatch(address[] calldata accounts, bool eligible) external onlyAdmin {
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; i++) {
            address account = accounts[i];
            if (account == address(0)) revert ZeroAddress();
            eligibleSchoolTransport[account] = eligible;
            emit EligibilityUpdated(account, eligible, _msgSender());
        }
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
     * @notice Reclama el beneficio mensual una vez por período.
     */
    function claim() external {
        address sender = _msgSender();
        uint256 period = currentPeriod();

        if (paused) revert PausedError();
        if (!IDENTITY_REGISTRY.isVerifiedChilean(sender)) revert NotVerified(sender);
        if (!eligibleSchoolTransport[sender]) revert NotEligible(sender);
        if (claimedByPeriod[sender][period]) revert AlreadyClaimed(sender, period);

        claimedByPeriod[sender][period] = true;
        TOKEN.mint(sender, BENEFIT_AMOUNT);

        emit Claimed(sender, BENEFIT_AMOUNT, period);
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
