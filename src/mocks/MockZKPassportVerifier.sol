// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IZKPassportVerifier} from "../IZKPassportVerifier.sol";

/**
  * @title MockZKPassportVerifier
* @notice Implementación mock del verificador ZKPassport para testing en Sepolia
* @dev SOLO PARA TESTING - No usar en producción
* 
  * Este contrato permite verificar y revocar direcciones manualmente para
* facilitar las pruebas del sistema CLPc en testnet.
  */
contract MockZKPassportVerifier is IZKPassportVerifier {

  // Mapping de direcciones verificadas
  mapping(address => bool) private _verified;


  // ============================================================
  // Atributos / Claims de edad (solo para testing manual)
  // ============================================================
  // Nota: esto NO forma parte de IZKPassportVerifier. Se expone como API extra
  // del mock para poder probar casos de elegibilidad (18+ / 65+).
  mapping(address => bool) private _over18;
  mapping(address => bool) private _over65;

  // Dirección del administrador
  address public admin;

  /**
    * @notice Emitido cuando se actualizan flags de edad de un usuario
  * @param account Dirección objetivo
  * @param over18 true si es mayor o igual a 18
  * @param over65 true si es mayor o igual a 65
  * @param timestamp Momento del update
  */
  event AgeFlagsUpdated(address indexed account, bool over18, bool over65, uint256 timestamp);

  /**
    * @notice Constructor que establece el deployer como admin
  */
  constructor() {
    admin = msg.sender;
  }

  /**
    * @notice Modificador que restringe acceso solo al admin
  */
  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  function _onlyAdmin() internal view {
    require(msg.sender == admin, "MockZKPassportVerifier: caller is not admin");
  }

  /**
    * @notice Verifica si una dirección ha sido marcada como verificada
  * @param account La dirección a consultar
  * @return bool true si está verificada
  */
  function isVerified(address account) external view override returns (bool) {
    return _verified[account];
  }

  /**
    * @notice Marca una dirección como verificada (solo admin)
  * @param account La dirección a verificar
  */
  function verify(address account) external onlyAdmin {
    require(account != address(0), "MockZKPassportVerifier: zero address");
    require(!_verified[account], "MockZKPassportVerifier: already verified");

    _verified[account] = true;
    emit AddressVerified(account, block.timestamp);
  }

  /**
    * @notice Verifica múltiples direcciones en batch (solo admin)
  * @param accounts Array de direcciones a verificar
  */
  function verifyBatch(address[] calldata accounts) external onlyAdmin {
    for (uint256 i = 0; i < accounts.length; i++) {
      address account = accounts[i];
      require(account != address(0), "MockZKPassportVerifier: zero address in batch");

      if (!_verified[account]) {
        _verified[account] = true;
        emit AddressVerified(account, block.timestamp);
      }
    }
  }

  /**
    * @notice Revoca la verificación de una dirección (solo admin)
  * @param account La dirección cuya verificación se revocará
  */
  function revoke(address account) external onlyAdmin {
    require(_verified[account], "MockZKPassportVerifier: not verified");

    _verified[account] = false;
    emit VerificationRevoked(account, block.timestamp);
  }

  // ============================================================
  // API extra: edad / elegibilidad (testing manual)
  // ============================================================

  /**
    * @notice Setea flags de edad para una cuenta (solo admin)
  * @dev Modelo simple para testing: flags booleanos.
    *      Reglas de consistencia:
    *      - Si over65 == true, over18 debe ser true (65+ implica 18+).
    * @param account Dirección objetivo
  * @param over18 true si mayor o igual a 18
  * @param over65 true si mayor o igual a 65
  */
  function setAgeFlags(address account, bool over18, bool over65) external onlyAdmin {
    require(account != address(0), "MockZKPassportVerifier: zero address");
    require(!over65 || over18, "MockZKPassportVerifier: over65 implies over18");

    _over18[account] = over18;
    _over65[account] = over65;

    emit AgeFlagsUpdated(account, over18, over65, block.timestamp);
  }

  /**
    * @notice Retorna si la cuenta es mayor o igual a 18 (según flags del mock)
  * @param account Dirección a consultar
  */
  function isOver18(address account) external view returns (bool) {
    return _over18[account];
  }

  /**
    * @notice Retorna si la cuenta es mayor o igual a 65 (según flags del mock)
  * @param account Dirección a consultar
  */
  function isOver65(address account) external view returns (bool) {
    return _over65[account];
  }

  /**
    * @notice Transfiere el rol de admin (solo admin actual)
  * @param newAdmin La nueva dirección admin
  */
  function transferAdmin(address newAdmin) external onlyAdmin {
    require(newAdmin != address(0), "MockZKPassportVerifier: zero address");
    admin = newAdmin;
  }
}

