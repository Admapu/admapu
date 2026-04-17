# [HIGH] Cambio inmediato de trusted forwarder en `CLPc` y `ClaimCLPc`

## Resumen
Antes de este hardening, tanto `CLPc` como `ClaimCLPc` permitían cambiar el `trustedForwarder` en una sola transacción administrativa.

Ese parámetro es sensible porque un forwarder confiable puede aportar el `msg.sender` efectivo al final del calldata. Si una clave admin/owner se compromete, un atacante puede instalar un forwarder malicioso y empezar a suplantar usuarios inmediatamente.

## Componentes afectados
- `src/CLPc.sol`
- `src/ClaimCLPc.sol`

## Riesgo operativo
1. Se compromete la cuenta con privilegios administrativos.
2. El atacante configura un forwarder arbitrario.
3. Las llamadas reenviadas empiezan a resolverse como si vinieran de usuarios legítimos.
4. Se abre una ventana para `claim()` gasless no autorizado o transferencias gasless con identidad falsificada.

Aunque el riesgo depende de que exista compromiso de la cuenta privilegiada, el impacto es alto porque la activación era instantánea.

## Remediación en esta rama
- `setTrustedForwarder(address)` ahora solo agenda el cambio.
- Se exige un delay on-chain de `2 days`.
- Se agregan:
  - `executeTrustedForwarderUpdate()`
  - `cancelTrustedForwarderUpdate()`
  - `pendingTrustedForwarder()`
  - `pendingTrustedForwarderEta()`

## Efecto esperado en scoring
Este cambio reduce la criticidad de administración privilegiada y de spoofing vía meta-transacciones. No elimina el riesgo administrativo, pero sí agrega una ventana observable para detectar y cancelar cambios no autorizados.

## Pasos de migración
1. Redeploy de `CLPc` y `ClaimCLPc`.
2. Configurar el nuevo forwarder con `setTrustedForwarder(address)`.
3. Esperar el timelock.
4. Ejecutar `executeTrustedForwarderUpdate()`.
5. Verificar con `trustedForwarder()` e `isTrustedForwarder(address)`.

## Checks post-remediación
- Un `executeTrustedForwarderUpdate()` temprano debe revertir.
- `cancelTrustedForwarderUpdate()` debe limpiar el estado pendiente.
- Solo la cuenta privilegiada debe poder agendar/ejecutar/cancelar.
- Las meta-tx deben seguir funcionando una vez ejecutado el cambio.
