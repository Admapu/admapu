# [MEDIUM] Controles administrativos no estandarizados en `ClaimCLPc`

## Resumen
`ClaimCLPc` usaba un `admin` custom con transferencia directa (`transferAdmin`) y lógica manual para pausa/permiso.

Eso no era un bug crítico por sí solo, pero sí empeoraba la auditabilidad:
- camino administrativo propio en vez de primitiva estándar
- cambio de administrador en un solo paso
- superficie extra para findings de mantenibilidad y seguridad operacional

## Componente afectado
- `src/ClaimCLPc.sol`

## Remediación en esta rama
`ClaimCLPc` ahora usa primitivas estándar de OpenZeppelin:

- `Ownable2Step`
- `Pausable`
- `ReentrancyGuard`

Cambios concretos:
- `admin` se reemplaza por `owner()`
- `transferAdmin(address)` se reemplaza por:
  - `transferOwnership(address)`
  - `acceptOwnership()`
- `claim()` queda protegido con `nonReentrant`
- la pausa usa `whenNotPaused`

## Justificación
Para un contrato de claim, el objetivo no es solo impedir exploits directos. También importa que la ruta de privilegios sea obvia para auditores, herramientas automáticas y operadores.

Usar primitivas estándar mejora:
- legibilidad
- compatibilidad con herramientas de análisis
- confiabilidad operacional

## Pasos de migración
1. Redeploy de `ClaimCLPc`.
2. Reasignar `MINTER_ROLE` al nuevo claim.
3. Revocar `MINTER_ROLE` al claim antiguo.
4. Si el ownership final será multisig, hacer:
   - `transferOwnership(multisig)`
   - desde la multisig, `acceptOwnership()`

## Checks post-remediación
- `owner()` retorna la cuenta correcta.
- `pendingOwner()` refleja la transferencia iniciada.
- `acceptOwnership()` solo puede ser ejecutado por el owner pendiente.
- `claim()` sigue funcionando una sola vez por usuario verificado.
