# Observability con Subgraph Studio

Este documento describe el scaffold inicial del subgraph para indexar CLPc en The Graph Studio y dejar los datos listos para ser consumidos desde un worker serverless.

## Objetivo

El subgraph quedó preparado para indexar:

- verificaciones y revocaciones de identidad
- transferencias de CLPc
- mints y burns detectados vía `Transfer`
- mints explícitos vía `TokensMinted`
- claims vía `Claimed`
- gasto de gas en wei por transacción, deduplicado por `txHash`

La idea es que un worker en Cloudflare consulte GraphQL y exponga un endpoint `/metrics` con formato estilo Prometheus.

## Ubicación

Los archivos del subgraph viven en [`subgraph/`](/home/boris/Code/admapu/admapu/subgraph).

Piezas principales:

- [`subgraph/subgraph.yaml`](/home/boris/Code/admapu/admapu/subgraph/subgraph.yaml)
- [`subgraph/schema.graphql`](/home/boris/Code/admapu/admapu/subgraph/schema.graphql)
- [`subgraph/src/helpers.ts`](/home/boris/Code/admapu/admapu/subgraph/src/helpers.ts)
- [`subgraph/src/verifier.ts`](/home/boris/Code/admapu/admapu/subgraph/src/verifier.ts)
- [`subgraph/src/token.ts`](/home/boris/Code/admapu/admapu/subgraph/src/token.ts)
- [`subgraph/src/claim.ts`](/home/boris/Code/admapu/admapu/subgraph/src/claim.ts)

## Métricas modeladas

### Globales

Entidad: `GlobalMetric(id: "current")`

- `currentVerifiedUsers`
- `currentRevokedUsers`
- `cumulativeVerificationEvents`
- `cumulativeRevocationEvents`
- `clpcTransferCount`
- `clpcTransferVolume`
- `clpcMintCount`
- `clpcMintVolume`
- `clpcBurnCount`
- `clpcBurnVolume`
- `claimCount`
- `claimVolume`
- `gasSpentWei`

### Series por ventana

Entidades:

- `HourlyMetric`
- `DailyMetric`

Cada bucket guarda:

- conteos y volúmenes del período
- delta neto de verificados
- snapshot del total actual de verificados y revocados
- gas acumulado del período

## Eventos indexados

### Verifier

- `AddressVerified(address,uint256)`
- `VerificationRevoked(address,uint256)`

### Token

- `Transfer(address,address,uint256)`
- `TokensMinted(address,uint256,uint256,uint256)`

### Claim

- `Claimed(address,uint256)`

## Convenciones importantes

- `clpcTransferCount` y `clpcTransferVolume` cuentan solo transferencias usuario a usuario.
- Los mints y burns se separan en métricas propias detectando `from == 0x0` o `to == 0x0` en `Transfer`.
- `gasSpentWei` se cobra una sola vez por transacción usando la entidad `ProcessedTransaction`, para no duplicar gas cuando una misma tx emite múltiples eventos.
- El gas se calcula como `receipt.gasUsed * transaction.gasPrice`.

## Limitación actual

El repo todavía no tiene un contrato específico para `Transporte Escolar`, por lo que ese beneficio no puede exponerse como métrica dedicada en el subgraph actual.

Para eso conviene crear un contrato/programa propio y emitir un evento explícito, por ejemplo:

```solidity
event BenefitClaimed(address indexed user, bytes32 indexed benefitId, uint256 amount);
```

Con eso se podría agregar:

- `transporteEscolarClaimCount`
- `transporteEscolarClaimVolume`

## Setup en The Graph Studio

### 1. Instalar dependencias

```bash
cd subgraph
npm install
```

### 2. Generar tipos y compilar

```bash
npm run codegen
npm run build
```

### 3. Crear el subgraph en Studio

1. Crear un subgraph nuevo en https://thegraph.com/studio/
2. Copiar el `deploy key`
3. Autenticar CLI

```bash
graph auth --studio <DEPLOY_KEY>
```

### 4. Deploy

```bash
npm run deploy:studio
```

## Ajustes antes del deploy

Antes de publicar, revisar:

- direcciones en [`subgraph/subgraph.yaml`](/home/boris/Code/admapu/admapu/subgraph/subgraph.yaml)
- `startBlock`
- nombre final del subgraph en el script `deploy:studio`

Si se redeployan contratos, actualizar esas direcciones antes de correr `codegen` y `build`.

## Siguiente paso recomendado

El siguiente componente natural es un worker serverless que:

1. consulte `GlobalMetric` y los buckets `HourlyMetric` y `DailyMetric`
2. transforme esos resultados a texto Prometheus
3. exponga `/metrics`

Eso permite integrar scraping desde Grafana Cloud, Prometheus o cualquier sistema compatible sin mantener backend tradicional.
