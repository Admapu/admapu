# CLPc — Deploy en Ethereum Sepolia

Fecha: 2026-02-23 (último redeploy)  
Red: Ethereum Sepolia  
Chain ID: `11155111`
Block: `10320005`

Para la mayoría de las direcciones estoy usando [ENS](https://ens.domains/) y, para faciltiar su uso, recomiendo usar [Blockscout](https://eth-sepolia.blockscout.com) como explorer ya que resuelve ENS automáticamente y EtherScan aun no soporta este feature en Sepolia.

La dirección es [admapu.eth](https://sepolia.app.ens.domains/admapu.eth) y todas las direcciones y contratos de más abajo están configurados como [subnames](https://sepolia.app.ens.domains/admapu.eth?tab=subnames).

## Direcciones y Contratos

**Admin / Deployer**
- ENS: `admin.admapu.eth`
- Address: `0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A`

**Verifier (MockZKPassportVerifier)**
- ENS: `mockzk.admapu.eth`
- Address: `0xcD59e6A78087BEA67a070b92bD7d8ff9d24a2647`

**IdentityRegistryAdapter**
- ENS: `identity.admapu.eth`
- Address: `0x0Ae1e5Dc605A88C6CD9A032C0b9C567406DBa98f`

**Token (CLPc)**
- ENS: `clpc.admapu.eth`
- Address: `0x889679fC04063Bd8706f5c2e5de26E3554FFFCa5`

**Claim (ClaimCLPc)**
- ENS: `claimclpc.admapu.eth`
- Address: `0x2E4F7D60AA4416ead3610bD0f90c80277A8D95BD`

**TransportBenefit**
- ENS: `transport.admapu.eth`
- Address: `0xD16B1A6c4b9243473b5e43b16a6A26AD8B71e102`

**Forwarder (ERC2771Forwarder)**
- ENS: *(opcional, recomendado)*
- Address: `0xE86e8FaF0b4c69C95BDdb495D51F94e2E7Be8Dfd`

## Blockscout links

- Verifier: https://eth-sepolia.blockscout.com/address/0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94
- IdentityRegistryAdapter: https://eth-sepolia.blockscout.com/address/0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21
- Token:    https://eth-sepolia.blockscout.com/address/0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553
- Claim:    https://eth-sepolia.blockscout.com/address/0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b
- TransportBenefit: https://eth-sepolia.blockscout.com/address/0xD16B1A6c4b9243473b5e43b16a6A26AD8B71e102?tab=index
- Forwarder: https://eth-sepolia.blockscout.com/address/0xA7a5A1B48A0e82b140a58315843b71F6e1d5c36e

## ABI: métodos expuestos

### MockZKPassportVerifier

- `admin()`
- `isVerified(address)`
- `verify(address)`
- `verifyBatch(address[])`
- `revoke(address)`
- `transferAdmin(address)`
- `isOver18(address)`
- `isOver65(address)`
- `setAgeFlags(address,bool,bool)`  // over18, over65

### CLPc

Roles / config:
- `DEFAULT_ADMIN_ROLE()`
- `defaultAdmin()`
- `pendingDefaultAdmin()`
- `defaultAdminDelay()`
- `beginDefaultAdminTransfer(address)`
- `acceptDefaultAdminTransfer()`
- `cancelDefaultAdminTransfer()`
- `MINTER_ROLE()`
- `PAUSER_ROLE()`
- `PROGRAM_ROLE()`
- `identityRegistry()`
- `setIdentityRegistry(address)`
- `executeIdentityRegistryUpdate()`
- `cancelIdentityRegistryUpdate()`
- `trustedForwarder()`
- `setMintingPaused(bool)`
- `setTrustedForwarder(address)`  // agenda el cambio
- `executeTrustedForwarderUpdate()`
- `cancelTrustedForwarderUpdate()`
- `pendingTrustedForwarder()`
- `pendingTrustedForwarderEta()`
- `mintingPaused()`
- `availableToMint()`
- `MAX_ANNUAL_SUPPLY()`
- `mintedThisYear()`
- `currentYear()`
- `getMintingInfo()`

ERC-20:
- `name()`, `symbol()`, `decimals()`, `totalSupply()`
- `balanceOf(address)`, `allowance(address,address)`
- `approve(address,uint256)`
- `transfer(address,uint256)`
- `transferFrom(address,address,uint256)`

Mint:
- `mint(address,uint256)`
- `mintBatch(address[],uint256[])`

Gating:
- `canReceive(address)`

### ClaimCLPc

- `owner()`
- `pendingOwner()`
- `transferOwnership(address)`
- `acceptOwnership()`
- `paused()`
- `setPaused(bool)`
- `trustedForwarder()`
- `setTrustedForwarder(address)`  // agenda el cambio
- `executeTrustedForwarderUpdate()`
- `cancelTrustedForwarderUpdate()`
- `pendingTrustedForwarder()`
- `pendingTrustedForwarderEta()`
- `claim()`
- `claimed(address)`
### TransportBenefit

- `TOKEN()`
- `IDENTITY_REGISTRY()`
- `BENEFIT_AMOUNT()`
- `currentPeriod()`
- `eligibleSchoolTransport(address)`
- `claimedByPeriod(address,uint256)`
- `setEligible(address,bool)`
- `setEligibleBatch(address[],bool)`
- `claim()`
- `setPaused(bool)`
- `setTrustedForwarder(address)`
- `trustedForwarder()`
- `isTrustedForwarder(address)`

## Cómo interactuar (CLI con Foundry)

### Variables de entorno

```bash
export SEPOLIA_RPC_URL="..."
export DEPLOYER_PK="0x..."   # Private key del admin/deployer
export ADMIN=$(cast wallet address --private-key "$DEPLOYER_PK")
export CLAIM_AMOUNT="..."    # Monto fijo del claim, considerar 8 decimales
export TRANSPORT_BENEFIT_AMOUNT="..."    # Monto mensual del beneficio, considerar 8 decimales
export FORWARDER_NAME="AdmapuForwarder"
```

Si quieres interactuar con el despliegue vigente documentado arriba, exporta además:

```bash
export ADMIN="0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A"
export VERIFIER="0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94"
export IDENTITY_REGISTRY_ADAPTER="0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21"
export TOKEN="0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553"
export CLAIM="0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b"
export TRANSPORT="0xD16B1A6c4b9243473b5e43b16a6A26AD8B71e102"
export FORWARDER="0xA7a5A1B48A0e82b140a58315843b71F6e1d5c36e"
```

## Redeploy reproducible del código actual

El flujo soportado por el repo hoy es:
1. Deploy base con `script/Deploy.s.sol`
2. Deploy de `ClaimCLPc` con `script/DeployClaim.s.sol`
3. Deploy de `ERC2771Forwarder` con `script/DeployForwarder.s.sol`
4. Wiring post-deploy (`MINTER_ROLE` + trusted forwarder timelocked)
5. Verificación en Blockscout
7. Deploy de `TransportBenefit` con `script/DeployTransport.s.sol`
8. Deploy de `ERC2771Forwarder` con `script/DeployForwarder.s.sol`
9. Wiring post-deploy (`MINTER_ROLE` + trusted forwarder)
10. Verificación en Blockscout

### 1) Build + tests

```bash
forge build
forge test -vv
```

### 2) Deploy base: verifier + adapter + token

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast -vv

export VERIFIER=$(jq -r '.returns.verifier.value' broadcast/Deploy.s.sol/11155111/run-latest.json)
export IDENTITY_REGISTRY_ADAPTER=$(jq -r '.returns.identityRegistryAdapter.value' broadcast/Deploy.s.sol/11155111/run-latest.json)
export TOKEN=$(jq -r '.returns.token.value' broadcast/Deploy.s.sol/11155111/run-latest.json)
```

### 3) Deploy claim

Requiere que `TOKEN`, `IDENTITY_REGISTRY_ADAPTER` y `CLAIM_AMOUNT` estén seteados.

```bash
forge script script/DeployClaim.s.sol:DeployClaim \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast -vv

export CLAIM=$(jq -r '.returns.claim.value' broadcast/DeployClaim.s.sol/11155111/run-latest.json)
```

### 4) Deploy transport benefit

Requiere que `TOKEN`, `IDENTITY_REGISTRY_ADAPTER` y `TRANSPORT_BENEFIT_AMOUNT` estén seteados.

`TransportBenefit` en la versión actual usa:
- `IDENTITY_REGISTRY_ADAPTER` solo para verificar ciudadanía chilena
- una allowlist interna (`setEligible`) para modelar temporalmente la elegibilidad de transporte escolar

```bash
forge script script/DeployTransport.s.sol:DeployTransport \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast -vv

export TRANSPORT=$(jq -r '.returns.transportBenefit.value' broadcast/DeployTransport.s.sol/11155111/run-latest.json)
```

### 5) Deploy forwarder

Requiere que `FORWARDER_NAME` esté seteado.

```bash
forge script script/DeployForwarder.s.sol:DeployForwarder \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast -vv

export FORWARDER=$(jq -r '.returns.forwarder.value' broadcast/DeployForwarder.s.sol/11155111/run-latest.json)
```

### 6) Wiring post-deploy

```bash
make grant-claim-minter
make check-claim-minter
make check-claim-config

make schedule-forwarder
make schedule-token-forwarder
make check-forwarder-pending
make check-token-forwarder-pending

# esperar el timelock antes de ejecutar
make execute-forwarder
make execute-token-forwarder

make grant-transport-minter
make check-transport-minter
make check-transport-config

make set-forwarder
make set-transport-forwarder
make set-token-forwarder
make check-forwarder
make check-transport-forwarder
make check-token-forwarder

FORWARDER="$FORWARDER" make check-forwarder-match
FORWARDER="$FORWARDER" make check-transport-forwarder-match
FORWARDER="$FORWARDER" make check-token-forwarder-match
```

### 7) Seed de elegibilidad para transporte escolar (PoC)

La elegibilidad de transporte escolar en la versión actual no vive en el registry compartido. Vive en `TransportBenefit` para evitar migrar el registry de `CLPc` durante esta etapa del PoC.

```bash
export USER_ADDR="0x..."
export ELIGIBLE=true

make check-user
make set-transport-eligible
make check-transport-eligible
```

### 8) Snapshot de variables para `.env`

```bash
export ADMIN="$ADMIN"
export VERIFIER="$VERIFIER"
export IDENTITY_REGISTRY_ADAPTER="$IDENTITY_REGISTRY_ADAPTER"
export TOKEN="$TOKEN"
export CLAIM="$CLAIM"
export TRANSPORT="$TRANSPORT"
export FORWARDER="$FORWARDER"
```

En este punto el sistema queda deployado y configurado para:
- verificación mock en Sepolia
- claim único por usuario
- beneficio mensual de transporte escolar con allowlist interna temporal
- transferencias restringidas a usuarios verificados
- meta-transacciones vía `ERC2771Forwarder`

## Flujo de mint vía claim

El mint de CLPc no sale de un "pool precargado". Se emite al momento del claim.

Resumen del flujo:
1. El usuario (verificado) ejecuta `claim()` directo o firma una meta-tx.
2. `ClaimCLPc` valida:
   - `paused == false`
   - `claimed[user] == false`
   - `IDENTITY_REGISTRY.isVerifiedChilean(user) == true`
3. Si pasa validaciones, `ClaimCLPc` llama `CLPc.mint(user, CLAIM_AMOUNT)`.
4. `CLPc` solo permite ese `mint` si `ClaimCLPc` tiene `MINTER_ROLE`.

Checks mínimos:

```bash
# Claim está habilitado
cast call "$CLAIM" "paused()(bool)" --rpc-url "$SEPOLIA_RPC_URL"

# Usuario aún no reclamó
# Nota: en zsh/bash, exporta USER_ADDR antes o pasa el address literal.
export USER_ADDR="0x..."
cast call "$CLAIM" "claimed(address)(bool)" "$USER_ADDR" --rpc-url "$SEPOLIA_RPC_URL"

# Claim tiene rol minter en token
# Este check solo da `true` después de ejecutar `make grant-claim-minter`
# en el wiring post-deploy.
MINTER_ROLE=$(cast call "$TOKEN" "MINTER_ROLE()(bytes32)" --rpc-url "$SEPOLIA_RPC_URL")
cast call "$TOKEN" "hasRole(bytes32,address)(bool)" "$MINTER_ROLE" "$CLAIM" --rpc-url "$SEPOLIA_RPC_URL"
```

### Meta-tx (ERC-2771)

Para que el usuario no pague gas:
- El usuario firma typed-data.
- El relayer envía `forwarder.execute(...)` y paga gas.
- Desde este hardening, la confianza en el forwarder se activa recién después del timelock.
- `ClaimCLPc`, `TransportBenefit` y `CLPc` deben confiar en ese forwarder.

```bash
# Forwarder confiable configurado en Claim
cast call "$CLAIM" "trustedForwarder()(address)" --rpc-url "$SEPOLIA_RPC_URL"
cast call "$CLAIM" "isTrustedForwarder(address)(bool)" "$FORWARDER" --rpc-url "$SEPOLIA_RPC_URL"

# Forwarder confiable configurado en TransportBenefit
cast call "$TRANSPORT" "trustedForwarder()(address)" --rpc-url "$SEPOLIA_RPC_URL"
cast call "$TRANSPORT" "isTrustedForwarder(address)(bool)" "$FORWARDER" --rpc-url "$SEPOLIA_RPC_URL"

# Forwarder confiable configurado en Token (para transfer gasless)
cast call "$TOKEN" "trustedForwarder()(address)" --rpc-url "$SEPOLIA_RPC_URL"
cast call "$TOKEN" "isTrustedForwarder(address)(bool)" "$FORWARDER" --rpc-url "$SEPOLIA_RPC_URL"
```

## Verificación de supply actual y cupo disponible

`CLPc` usa límite anual de emisión. Comandos útiles:

```bash
# supply emitido total (circulante emitido por mint)
cast call "$TOKEN" "totalSupply()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"

# cupo disponible para seguir minteando este año
cast call "$TOKEN" "availableToMint()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"

# límite anual y uso acumulado del año actual
cast call "$TOKEN" "MAX_ANNUAL_SUPPLY()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"
cast call "$TOKEN" "mintedThisYear()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"
cast call "$TOKEN" "currentYear()(uint16)" --rpc-url "$SEPOLIA_RPC_URL"
```

Si quieres verlo en unidades CLPc (8 decimales), divide por `1e8`.

## Ver transacciones en explorer

Sí, se puede ver todo en Sepolia explorer:

- Etherscan (address txs):  
  `https://sepolia.etherscan.io/address/<ADDRESS>#txns`
- Blockscout (address txs):  
  `https://eth-sepolia.blockscout.com/address/<ADDRESS>?tab=txs`

Para `TOKEN`, también puedes revisar transferencias ERC-20:
- Etherscan: `.../address/<TOKEN>#tokentxns`
- Blockscout: `.../address/<TOKEN>?tab=token_transfers`

## Verificación de contratos (source verification)

Estado actual en Blockscout (Sepolia):
- `MockZKPassportVerifier` (`VERIFIER`): verificado
- `ZKPassportIdentityRegistryAdapter` (`IDENTITY_REGISTRY_ADAPTER`): verificado
- `CLPc` (`TOKEN`): verificado
- `ClaimCLPc` (`CLAIM`): verificado
- `TransportBenefit` (`TRANSPORT`): verificado
- `ERC2771Forwarder` (`FORWARDER`): verificado

### Comandos de verificación (Foundry + Blockscout)

```bash
export BS_API="https://eth-sepolia.blockscout.com/api/"
export ETHERSCAN_API_KEY="blockscout"
```

Verifier:

```bash
forge verify-contract "$VERIFIER" src/mocks/MockZKPassportVerifier.sol:MockZKPassportVerifier \
  --chain-id 11155111 \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Identity Registry Adapter:

```bash
ARGS_ADAPTER=$(cast abi-encode "constructor(address)" "$VERIFIER")
forge verify-contract "$IDENTITY_REGISTRY_ADAPTER" src/ZKPassportIdentityRegistryAdapter.sol:ZKPassportIdentityRegistryAdapter \
  --chain-id 11155111 \
  --constructor-args "$ARGS_ADAPTER" \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Token `CLPc`:

```bash
ARGS_TOKEN=$(cast abi-encode "constructor(address,address)" "$IDENTITY_REGISTRY_ADAPTER" "$ADMIN")
forge verify-contract "$TOKEN" src/CLPc.sol:CLPc \
  --chain-id 11155111 \
  --constructor-args "$ARGS_TOKEN" \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Claim `ClaimCLPc`:

```bash
CLAIM_AMOUNT=$(cast call "$CLAIM" "CLAIM_AMOUNT()(uint256)" --rpc-url "$SEPOLIA_RPC_URL" | awk '{print $1}')
CLAIM_OWNER=$(cast call "$CLAIM" "owner()(address)" --rpc-url "$SEPOLIA_RPC_URL")
ARGS_CLAIM=$(cast abi-encode "constructor(address,address,uint256,address)" "$TOKEN" "$IDENTITY_REGISTRY_ADAPTER" "$CLAIM_AMOUNT" "$CLAIM_OWNER")

forge verify-contract "$CLAIM" src/ClaimCLPc.sol:ClaimCLPc \
  --chain-id 11155111 \
  --constructor-args "$ARGS_CLAIM" \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Transport `TransportBenefit`:

```bash
TRANSPORT_AMOUNT=$(cast call "$TRANSPORT" "BENEFIT_AMOUNT()(uint256)" --rpc-url "$SEPOLIA_RPC_URL" | awk '{print $1}')
TRANSPORT_ADMIN=$(cast call "$TRANSPORT" "admin()(address)" --rpc-url "$SEPOLIA_RPC_URL")
ARGS_TRANSPORT=$(cast abi-encode "constructor(address,address,uint256,address)" "$TOKEN" "$IDENTITY_REGISTRY_ADAPTER" "$TRANSPORT_AMOUNT" "$TRANSPORT_ADMIN")

forge verify-contract "$TRANSPORT" src/TransportBenefit.sol:TransportBenefit \
  --chain-id 11155111 \
  --constructor-args "$ARGS_TRANSPORT" \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Forwarder `ERC2771Forwarder`:

```bash
ARGS_FWD=$(cast abi-encode "constructor(string)" "$FORWARDER_NAME")

# Nota: se usa FOUNDRY_SRC=. para resolver correctamente la ruta en lib/openzeppelin-contracts
FOUNDRY_SRC=. forge verify-contract "$FORWARDER" lib/openzeppelin-contracts/contracts/metatx/ERC2771Forwarder.sol:ERC2771Forwarder \
  --chain-id 11155111 \
  --constructor-args "$ARGS_FWD" \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

### Revisar estado de verificación

Si `forge verify-contract` retorna `GUID`, puedes consultar el estado con:

```bash
forge verify-check "<GUID>" \
  --chain-id 11155111 \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```
