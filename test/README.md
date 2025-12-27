# Tests (Foundry)

Este directorio contiene la suite de pruebas de contratos con Foundry.

## Cómo ejecutar las pruebas localmente

```bash
forge test
```

Para correr una prueba específica:

```bash
forge test --match-test <NOMBRE_DEL_TEST>
```

## CI

El workflow de CI ejecuta `forge test` en cada push y pull request.
Ver `.github/workflows/ci.yml`.

## Cobertura actual (alto nivel)

- Roles y permisos: admin/minter/pauser (AccessControl).
- Minting: éxito, pausado, límites anuales, batch mint y casos de error.
- Gating: transferencias entre wallets verificadas y reverts por verificación faltante.

## Pendientes / mejoras futuras

- Eventos: validar emisiones relevantes (`TokensMinted`, `MintingPauseToggled`, `AnnualSupplyReset`).
- Rutas edge-case de `mintBatch`: éxito con múltiples receptores y mezcla de montos.
- Verificación de vistas: `availableToMint()` y `getMintingInfo()` en distintos escenarios.
- Integración con verificador real (cuando esté el contrato productivo).
