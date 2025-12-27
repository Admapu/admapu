// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IZKPassportVerifier} from "./IZKPassportVerifier.sol";

/**
 * @title CLPc
 * @notice Stablecoin para ciudadanos chilenos verificados mediante Zero-Knowledge Proofs
 * @dev Token ERC20 con restricciones de transferencia basadas en verificación de identidad
 *
 * Características principales:
 * - Solo ciudadanos chilenos verificados pueden recibir y transferir tokens
 * - Sistema de roles para administración, minting y pausas
 * - Límite de mint anual para control de suministro
 * - Mint pausable para situaciones de emergencia
 * - Integración con verificador ZKPassport para validación de identidad
 *
 * Roles:
 * - DEFAULT_ADMIN_ROLE: Administración general del contrato
 * - MINTER_ROLE: Autorizado para mintear tokens
 * - PAUSER_ROLE: Autorizado para pausar el minting
 * - PROGRAM_ROLE: Contratos de programas sociales autorizados
 */
contract CLPc is ERC20, AccessControl, Pausable {
    // ============ Roles ============

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PROGRAM_ROLE = keccak256("PROGRAM_ROLE");

    // ============ Constantes ============

    /// @notice Número de decimales del token (8 para alinearse con sats de Bitcoin)
    uint8 private constant DECIMALS = 8;

    /// @notice Suministro máximo anual: 18 mil millones de tokens
    uint256 public constant MAX_ANNUAL_SUPPLY = 18_000_000_000 * 10 ** DECIMALS;

    // ============ Variables de Estado ============

    /// @notice Referencia al contrato verificador de ZKPassport
    IZKPassportVerifier public zkVerifier;

    /// @notice Año actual para tracking de límite anual
    uint256 public currentYear;

    /// @notice Cantidad minteada en el año actual
    uint256 public mintedThisYear;

    /// @notice Timestamp del último reset de año
    uint256 public lastYearReset;

    /// @notice Flag para control de pausado de minting
    bool public mintingPaused;

    // ============ Eventos ============

    /**
     * @notice Emitido cuando se actualiza el verificador ZKPassport
     * @param oldVerifier Dirección del verificador anterior
     * @param newVerifier Dirección del nuevo verificador
     */
    event ZKVerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    /**
     * @notice Emitido cuando se mintean tokens
     * @param to Destinatario de los tokens
     * @param amount Cantidad minteada
     * @param year Año en que se realizó el mint
     * @param totalMintedThisYear Total minteado en el año
     */
    event TokensMinted(address indexed to, uint256 amount, uint256 year, uint256 totalMintedThisYear);

    /**
     * @notice Emitido cuando se pausa o despausa el minting
     * @param paused Estado de pausa (true = pausado)
     */
    event MintingPauseToggled(bool paused);

    /**
     * @notice Emitido cuando se resetea el contador anual
     * @param newYear Nuevo año
     * @param previousMinted Cantidad minteada en el año anterior
     */
    event AnnualSupplyReset(uint256 newYear, uint256 previousMinted);

    // ============ Errores Personalizados ============

    error UnverifiedSender(address sender);
    error UnverifiedRecipient(address recipient);
    error MintingIsPaused();
    error AnnualSupplyExceeded(uint256 requested, uint256 available);
    error ZeroAddress();
    error ZeroAmount();

    // ============ Constructor ============

    /**
     * @notice Constructor que inicializa el token CLPc
     * @param _zkVerifier Dirección del contrato verificador ZKPassport
     * @param _admin Dirección que recibirá el rol de admin
     */
    constructor(address _zkVerifier, address _admin) ERC20("Chilean Peso Coin", "CLPc") {
        if (_zkVerifier == address(0)) revert ZeroAddress();
        if (_admin == address(0)) revert ZeroAddress();

        zkVerifier = IZKPassportVerifier(_zkVerifier);

        // Configurar roles iniciales
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);

        // Inicializar tracking de año
        currentYear = _getCurrentYear();
        lastYearReset = block.timestamp;
        mintedThisYear = 0;
        mintingPaused = false;
    }

    // ============ Funciones de Configuración ============

    /**
     * @notice Actualiza el contrato verificador ZKPassport
     * @param _newVerifier Nueva dirección del verificador
     * @dev Solo puede ser llamado por DEFAULT_ADMIN_ROLE
     */
    function setZkVerifier(address _newVerifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newVerifier == address(0)) revert ZeroAddress();

        address oldVerifier = address(zkVerifier);
        zkVerifier = IZKPassportVerifier(_newVerifier);

        emit ZKVerifierUpdated(oldVerifier, _newVerifier);
    }

    /**
     * @notice Pausa o despausa el minting de tokens
     * @param _pause true para pausar, false para despausar
     * @dev Solo puede ser llamado por PAUSER_ROLE
     */
    function setMintingPaused(bool _pause) external onlyRole(PAUSER_ROLE) {
        mintingPaused = _pause;
        emit MintingPauseToggled(_pause);
    }

    // ============ Funciones de Minting ============

    /**
     * @notice Mintea tokens a una dirección verificada
     * @param to Destinatario de los tokens (debe estar verificado)
     * @param amount Cantidad de tokens a mintear
     * @dev Solo puede ser llamado por MINTER_ROLE
     * @dev Verifica límites anuales y estado de verificación
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (mintingPaused) revert MintingIsPaused();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        // Verificar que el destinatario esté verificado (excepto contratos de programa)
        if (!hasRole(PROGRAM_ROLE, to) && !zkVerifier.isVerified(to)) {
            revert UnverifiedRecipient(to);
        }

        // Resetear contador si cambió el año
        _checkAndResetAnnualSupply();

        // Verificar límite anual
        uint256 newTotal = mintedThisYear + amount;
        if (newTotal > MAX_ANNUAL_SUPPLY) {
            revert AnnualSupplyExceeded(amount, MAX_ANNUAL_SUPPLY - mintedThisYear);
        }

        // Actualizar contador y mintear
        mintedThisYear = newTotal;
        _mint(to, amount);

        emit TokensMinted(to, amount, currentYear, mintedThisYear);
    }

    /**
     * @notice Mintea tokens a múltiples direcciones (batch minting)
     * @param recipients Array de direcciones destinatarias
     * @param amounts Array de cantidades correspondientes
     * @dev Solo puede ser llamado por MINTER_ROLE
     */
    function mintBatch(address[] calldata recipients, uint256[] calldata amounts) external onlyRole(MINTER_ROLE) {
        require(recipients.length == amounts.length, "CLPc: arrays length mismatch");
        require(recipients.length > 0, "CLPc: empty arrays");

        if (mintingPaused) revert MintingIsPaused();

        // Resetear contador si cambió el año
        _checkAndResetAnnualSupply();

        uint256 totalAmount = 0;

        // Calcular total y validar
        for (uint256 i = 0; i < recipients.length; i++) {
            address to = recipients[i];
            uint256 amount = amounts[i];

            if (to == address(0)) revert ZeroAddress();
            if (amount == 0) revert ZeroAmount();

            // Verificar destinatario
            if (!hasRole(PROGRAM_ROLE, to) && !zkVerifier.isVerified(to)) {
                revert UnverifiedRecipient(to);
            }

            totalAmount += amount;
        }

        // Verificar límite anual
        uint256 newTotal = mintedThisYear + totalAmount;
        if (newTotal > MAX_ANNUAL_SUPPLY) {
            revert AnnualSupplyExceeded(totalAmount, MAX_ANNUAL_SUPPLY - mintedThisYear);
        }

        // Actualizar contador
        mintedThisYear = newTotal;

        // Mintear a cada destinatario
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
            emit TokensMinted(recipients[i], amounts[i], currentYear, mintedThisYear);
        }
    }

    // ============ Overrides de Transferencia ============

    /**
     * @notice Override de _update para aplicar restricciones de verificación ZK
     * @dev Valida que sender y recipient estén verificados antes de permitir transferencia
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        // Permitir minting (from == address(0)) y burning (to == address(0))
        if (from != address(0) && to != address(0)) {
            // Verificar que ambas partes estén verificadas o sean contratos de programa
            bool senderVerified = hasRole(PROGRAM_ROLE, from) || zkVerifier.isVerified(from);
            bool recipientVerified = hasRole(PROGRAM_ROLE, to) || zkVerifier.isVerified(to);

            if (!senderVerified) revert UnverifiedSender(from);
            if (!recipientVerified) revert UnverifiedRecipient(to);
        }

        super._update(from, to, value);
    }

    // ============ Funciones de Vista ============

    /**
     * @notice Retorna el número de decimales del token
     * @return uint8 Número de decimales (8)
     */
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Verifica si una dirección puede recibir tokens
     * @param account Dirección a verificar
     * @return bool true si la dirección puede recibir tokens
     */
    function canReceive(address account) external view returns (bool) {
        return hasRole(PROGRAM_ROLE, account) || zkVerifier.isVerified(account);
    }

    /**
     * @notice Retorna la cantidad disponible para mintear en el año actual
     * @return uint256 Cantidad disponible
     */
    function availableToMint() external view returns (uint256) {
        _checkIfNewYear(); // Check pero no modifica estado

        if (mintedThisYear >= MAX_ANNUAL_SUPPLY) {
            return 0;
        }
        return MAX_ANNUAL_SUPPLY - mintedThisYear;
    }

    /**
     * @notice Retorna información completa del estado de minting
     * @return year Año actual
     * @return minted Cantidad minteada este año
     * @return available Cantidad disponible
     * @return paused Si el minting está pausado
     */
    function getMintingInfo() external view returns (uint256 year, uint256 minted, uint256 available, bool paused) {
        _checkIfNewYear();

        year = currentYear;
        minted = mintedThisYear;
        available = mintedThisYear >= MAX_ANNUAL_SUPPLY ? 0 : MAX_ANNUAL_SUPPLY - mintedThisYear;
        paused = mintingPaused;
    }

    // ============ Funciones Internas ============

    /**
     * @notice Verifica si cambió el año y resetea el contador si es necesario
     * @dev Función que modifica estado
     */
    function _checkAndResetAnnualSupply() internal {
        uint256 newYear = _getCurrentYear();

        if (newYear > currentYear) {
            emit AnnualSupplyReset(newYear, mintedThisYear);

            currentYear = newYear;
            mintedThisYear = 0;
            lastYearReset = block.timestamp;
        }
    }

    /**
     * @notice Verifica si cambió el año (solo lectura)
     * @dev Función view que no modifica estado
     */
    function _checkIfNewYear() internal view {
        // Solo para verificaciones view, no modifica estado
    }

    /**
     * @notice Obtiene el año actual basado en el timestamp
     * @return uint256 Año actual
     */
    function _getCurrentYear() internal view returns (uint256) {
        // Aproximación simple: año base 2025 + años transcurridos
        // 31536000 segundos = 365 días
        return 2025 + ((block.timestamp - 1735689600) / 31536000);
        // 1735689600 = timestamp aproximado de Jan 1, 2025
    }

    // ============ Soporte de Interfaces ============

    /**
     * @notice Verifica soporte de interfaces
     * @param interfaceId ID de la interfaz
     * @return bool true si la interfaz es soportada
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

