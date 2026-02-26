# Smoke tests (manual runbook)

Este documento describe un flujo **manual y rápido** para validar que el proyecto está sano antes y después de deployar cambios de contratos.

> Alcance: checks de compilación, tests de Foundry, validación del script de deploy en seco y verificación básica post-deploy en Sepolia.

## Prerrequisitos

- Estar en la raíz del repo `admapu`.
- Tener Foundry instalado (`forge`, `cast`).
- Tener variables de entorno configuradas en `.env` (al menos):
  - `SEPOLIA_RPC_URL`
  - `DEPLOYER_PK`
  - Para checks post-deploy con Makefile:
    - `TOKEN`
    - `VERIFIER`

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

## 2) Smoke del deploy script (dry-run, sin broadcast)

Validar que el script de deploy no falla al ejecutarse contra la red objetivo:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url "$SEPOLIA_RPC_URL" -vv
```

Criterio de éxito:
- El script corre de principio a fin sin revert.
- Se muestran logs esperados de direcciones/flujo del script.

## 3) Smoke post-deploy (validación mínima en Sepolia)

Una vez deployados los contratos, actualizar `.env` con direcciones nuevas (`TOKEN`, `VERIFIER`) y ejecutar checks básicos.

### 3.0 Direcciones vigentes (Sepolia, deploy 2026-02-23)

- `VERIFIER=0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94`
- `IDENTITY_REGISTRY_ADAPTER=0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21`
- `TOKEN=0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553`
- `CLAIM=0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b`
- `FORWARDER=0xA7a5A1B48A0e82b140a58315843b71F6e1d5c36e`
- `ADMIN=0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A`

### 3.1 Estado de minting

```bash
make check-status
```

Esperado: responde `true|false` (pausado/no pausado), sin error RPC.

### 3.2 Verificación de usuario

```bash
USER_ADDR=0x... make check-user
```

### 3.3 (PoC con mock) Marcar usuario verificado y re-validar

```bash
USER_ADDR=0x... make whitelist-user
USER_ADDR=0x... make check-user
```

Esperado:
- `whitelist-user` ejecuta sin revert.
- `check-user` devuelve `true` para esa wallet.

## 4) Checklist de salida (go/no-go)

Antes de continuar con integración frontend/backend:

- [ ] `forge build` OK
- [ ] `forge test -vv` OK
- [ ] `forge script ...Deploy` (dry-run) OK
- [ ] `make check-status` OK
- [ ] `check-user` / `whitelist-user` (si aplica mock) OK

Si algún paso falla, **detener deploy** y corregir antes de avanzar.

## Notas

- Este runbook intencionalmente evita automatización (`smoke.sh`) para privilegiar una revisión manual explícita en cada release.
- Para producción, complementar con controles adicionales (roles/permissions, eventos críticos, monitoreo y plan de rollback).
- Si vas a usar flujo de claim, el contrato `ClaimCLPc` se deploya por separado y requiere configuración posterior (al menos `MINTER_ROLE` en `CLPc` para el address de claim).
