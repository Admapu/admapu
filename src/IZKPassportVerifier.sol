// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
  * @title IZKPassportVerifier
* @notice Interfaz para verificación de identidad chilena mediante Zero-Knowledge Proofs
* @dev Esta interfaz define el contrato que verifica pruebas ZK de nacionalidad chilena
*/
interface IZKPassportVerifier {
  /**
    * @notice Verifica si una dirección ha sido verificada como ciudadano chileno
  * @param account La dirección a verificar
  * @return bool true si la dirección está verificada, false en caso contrario
  */
  function isVerified(address account) external view returns (bool);

  /**
    * @notice Evento emitido cuando una dirección es verificada
  * @param account La dirección verificada
  * @param timestamp El timestamp de la verificación
  */
  event AddressVerified(address indexed account, uint256 timestamp);

  /**
    * @notice Evento emitido cuando se revoca la verificación de una dirección
  * @param account La dirección cuya verificación fue revocada
  * @param timestamp El timestamp de la revocación
  */
  event VerificationRevoked(address indexed account, uint256 timestamp);
}

