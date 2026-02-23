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
