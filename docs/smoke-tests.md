# Smoke tests (manual runbook)

Este documento describe un flujo **manual y rápido** para validar que el proyecto está sano antes y después de deployar cambios de contratos.

> Alcance: checks de compilación, tests de Foundry, validación del script de deploy en seco y verificación básica post-deploy en Sepolia.

El repositorio también expone `make smoke-test`, que imprime el checklist mínimo para operadores.

## Prerrequisitos

- Estar en la raíz del repo `admapu`.
- Tener Foundry instalado (`forge`, `cast`).
- Tener variables de entorno configuradas en `.env` (al menos):
  - `SEPOLIA_RPC_URL`
  - `DEPLOYER_PK`
  - `CLAIM_AMOUNT`
  - `TRANSPORT_BENEFIT_AMOUNT`
  - `FORWARDER_NAME`
  - Para checks post-deploy con Makefile:
    - `TOKEN`
    - `VERIFIER`
    - `CLAIM`
    - `TRANSPORT`
    - `FORWARDER`

## 1) Smoke local (compilación + tests)

```bash
cd ~/.openclaw/workspace-code/admapu

# opcional: actualizar dependencias si corresponde
forge install

# compilar
forge build

# ejecutar suite de tests
forge test -vv
```

Criterio de éxito:
- `forge build` sin errores.
- `forge test` sin tests fallidos.

## 2) Smoke de scripts de deploy (dry-run, sin broadcast)

Validar que los scripts de deploy no fallan al ejecutarse contra la red objetivo:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url "$SEPOLIA_RPC_URL" -vv
forge script script/DeployClaim.s.sol:DeployClaim --rpc-url "$SEPOLIA_RPC_URL" -vv
forge script script/DeployTransport.s.sol:DeployTransport --rpc-url "$SEPOLIA_RPC_URL" -vv
forge script script/DeployForwarder.s.sol:DeployForwarder --rpc-url "$SEPOLIA_RPC_URL" -vv
```

Criterio de éxito:
- Cada script corre de principio a fin sin revert.
- Se muestran logs esperados de direcciones/flujo.

## 3) Smoke post-deploy (validación mínima en Sepolia)

Una vez deployados los contratos, actualizar `.env` con direcciones nuevas y ejecutar wiring + checks básicos.

### 3.0 Direcciones vigentes (Sepolia, deploy 2026-02-23)

- `VERIFIER=0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94`
- `IDENTITY_REGISTRY_ADAPTER=0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21`
- `TOKEN=0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553`
- `CLAIM=0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b`
- `TRANSPORT=0xD16B1A6c4b9243473b5e43b16a6A26AD8B71e102`
- `FORWARDER=0xA7a5A1B48A0e82b140a58315843b71F6e1d5c36e`
- `ADMIN=0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A`

### 3.1 Estado de minting

```bash
make check-status
```

Esperado: responde `true|false` (pausado/no pausado), sin error RPC.

### 3.2 Verificación de usuario

```bash
export USER_ADDR="0x..."
make check-user
```

### 3.3 Wiring mínimo post-deploy

```bash
make grant-claim-minter
make check-claim-minter
make check-claim-config

make grant-transport-minter
make check-transport-minter
make check-transport-config

make schedule-forwarder
make schedule-token-forwarder
make check-forwarder-pending
make check-token-forwarder-pending

# esperar el timelock on-chain antes de ejecutar
make execute-forwarder
make execute-token-forwarder

make set-transport-forwarder

make check-forwarder
make check-token-forwarder
make check-transport-forwarder
FORWARDER="$FORWARDER" make check-forwarder-match
FORWARDER="$FORWARDER" make check-token-forwarder-match
FORWARDER="$FORWARDER" make check-transport-forwarder-match
```

Esperado:
- `CLAIM` tiene `MINTER_ROLE` en `TOKEN`.
- `TRANSPORT` tiene `MINTER_ROLE` en `TOKEN`.
- `ClaimCLPc` y `CLPc` confían en el mismo `FORWARDER`.
- `TransportBenefit` también confía en el mismo `FORWARDER`.
- Antes de `grant-claim-minter`, el check de minter puede devolver `false`. Eso es esperado.
- El trusted forwarder no queda activo hasta ejecutar el timelock.

### 3.4 (PoC con mock) Marcar usuario verificado y re-validar

```bash
export USER_ADDR="0x..."
make whitelist-user
make check-user
```

Esperado:
- `whitelist-user` ejecuta sin revert.
- `check-user` devuelve `true` para esa wallet.

### 3.5 Validar claim y transporte

```bash
export USER_ADDR="0x..."
make check-claim
USER_PK="0x..." make claim-direct
make check-claim

export ELIGIBLE=true
make set-transport-eligible
make check-transport-eligible
export PERIOD=$(cast call "$TRANSPORT" "currentPeriod()(uint256)" --rpc-url "$SEPOLIA_RPC_URL")
make check-transport-claimed
USER_PK="0x..." make claim-transport-direct
make check-transport-claimed
```

Esperado:
- usuario verificado puede ejecutar `claim()` una vez
- usuario verificado y elegible puede ejecutar `TransportBenefit.claim()` una vez por período
- usuario no verificado no puede reclamar ninguno de los dos beneficios

## 4) Checklist de salida (go/no-go)

Antes de continuar con integración frontend/backend:

- [ ] `forge build` OK
- [ ] `forge test -vv` OK
- [ ] `forge script ...Deploy` / `...DeployClaim` / `...DeployTransport` / `...DeployForwarder` (dry-run) OK
- [ ] `grant-claim-minter` / `grant-transport-minter` / forwarders configurados OK
- [ ] `make check-status` OK
- [ ] `check-user` / `whitelist-user` (si aplica mock) OK
- [ ] claim y transporte validados con un usuario de prueba

Si algún paso falla, **detener deploy** y corregir antes de avanzar.

## Notas

- Este runbook intencionalmente evita automatización (`smoke.sh`) para privilegiar una revisión manual explícita en cada release.
- Para producción, complementar con controles adicionales (roles/permissions, eventos críticos, monitoreo y plan de rollback).
- El flujo actual sigue requiriendo wiring post-deploy: `MINTER_ROLE` para `CLAIM` y `TRANSPORT`, más trusted forwarder compartido entre `CLAIM`, `TOKEN` y `TRANSPORT`.
- Desde este hardening, el wiring del forwarder es de dos pasos: agendar y luego ejecutar después del delay.
