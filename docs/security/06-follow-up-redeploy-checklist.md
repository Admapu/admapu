# Follow-up operativo para redeploy y rewiring

Este checklist asume que los cambios de seguridad modifican bytecode y, por lo tanto, requieren redeploy de al menos `CLPc` y `ClaimCLPc`.

## 1. Preparar release
1. Ejecutar `forge test -vv`.
2. Confirmar direcciones de destino:
   - admin inicial / multisig
   - verifier
   - identity registry adapter
   - forwarder
3. Definir si ENS/subnames se actualizarán en la misma ventana o en una segunda etapa.

## 2. Deploy de contratos nuevos
1. Deploy base con `script/Deploy.s.sol`.
2. Deploy de `ClaimCLPc` con `script/DeployClaim.s.sol`.
3. Deploy de `ERC2771Forwarder` solo si también cambiará el forwarder.

## 3. Wiring mínimo obligatorio
1. Otorgar `MINTER_ROLE` del token nuevo al claim nuevo.
2. Verificar que `ClaimCLPc.IDENTITY_REGISTRY` y `CLPc.identityRegistry` apunten a la misma fuente.
3. Agendar trusted forwarder en `CLAIM`.
4. Agendar trusted forwarder en `TOKEN`.
5. Esperar el timelock.
6. Ejecutar el cambio pendiente en ambos contratos.

## 4. Transferencia de control administrativo
1. En `CLPc`, iniciar transferencia de `DEFAULT_ADMIN_ROLE` si el owner final será otra cuenta o multisig.
2. En `ClaimCLPc`, ejecutar `transferOwnership(newOwner)`.
3. Desde la cuenta destino, ejecutar `acceptOwnership()` para claim.
4. Completar el flujo de admin delay de `CLPc` antes de considerar cerrado el release.

## 5. Actualización de integraciones
1. Actualizar `.env` y variables de despliegue.
2. Actualizar frontend/backend con nuevas direcciones.
3. Actualizar subgraph/indexadores.
4. Actualizar workers/relayers que usen `CLAIM`, `TOKEN` o `FORWARDER`.
5. Actualizar ENS/subnames si esas direcciones son el punto de entrada oficial.

## 6. Verificación y publicación
1. Verificar contratos nuevos en Blockscout.
2. Confirmar que el explorer muestra source code y ABI correctos.
3. Revisar nuevamente el security score por contrato.
4. Documentar las direcciones nuevas en `docs/deployments/`.

## 7. Desactivación de contratos antiguos
1. Revocar permisos críticos del claim antiguo.
2. Quitar referencias operativas al token/claim antiguos.
3. Marcar las direcciones previas como deprecadas en documentación interna.
4. Si hay relayer activo, impedir que siga enviando tráfico al contrato antiguo.

## 8. Smoke test post-release
1. Usuario verificado puede hacer `claim()` una sola vez.
2. Usuario no verificado no puede hacer `claim()`.
3. Transferencia verificado -> verificado funciona.
4. Transferencia a no verificado revierte.
5. Meta-tx funciona solo después de ejecutar el timelock del forwarder.
