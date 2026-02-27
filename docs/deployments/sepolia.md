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
- Address: `0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94`

**IdentityRegistryAdapter**
- ENS: `identity.admapu.eth`
- Address: `0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21`

**Token (CLPc)**
- ENS: `clpc.admapu.eth`
- Address: `0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553`

**Claim (ClaimCLPc)**
- ENS: `claimclpc.admapu.eth`
- Address: `0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b`

**Forwarder (ERC2771Forwarder)**
- ENS: *(opcional, recomendado)*
- Address: `0xA7a5A1B48A0e82b140a58315843b71F6e1d5c36e`

## Blockscout links

- Verifier: https://eth-sepolia.blockscout.com/address/0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94
- IdentityRegistryAdapter: https://eth-sepolia.blockscout.com/address/0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21
- Token:    https://eth-sepolia.blockscout.com/address/0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553
- Claim:    https://eth-sepolia.blockscout.com/address/0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b
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
- `MINTER_ROLE()`
- `PAUSER_ROLE()`
- `PROGRAM_ROLE()`
- `identityRegistry()`
- `setIdentityRegistry(address)`
- `setMintingPaused(bool)`
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

## Cómo interactuar (CLI con Foundry)

### Variables de entorno

```bash
export SEPOLIA_RPC_URL="..."
export DEPLOYER_PK="0x..."   # Private key del admin/deployer

export ADMIN="0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A"
export VERIFIER="0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94"
export IDENTITY_REGISTRY_ADAPTER="0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21"
export TOKEN="0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553"
export CLAIM="0x61a8e1725Bb5187CF35Bc1A682Ce55b77E68016b"
export FORWARDER="0xA7a5A1B48A0e82b140a58315843b71F6e1d5c36e"
```

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
cast call "$CLAIM" "claimed(address)(bool)" "$USER_ADDR" --rpc-url "$SEPOLIA_RPC_URL"

# Claim tiene rol minter en token
MINTER_ROLE=$(cast call "$TOKEN" "MINTER_ROLE()(bytes32)" --rpc-url "$SEPOLIA_RPC_URL")
cast call "$TOKEN" "hasRole(bytes32,address)(bool)" "$MINTER_ROLE" "$CLAIM" --rpc-url "$SEPOLIA_RPC_URL"
```

### Meta-tx (ERC-2771)

Para que el usuario no pague gas:
- El usuario firma typed-data.
- El relayer envía `forwarder.execute(...)` y paga gas.
- `ClaimCLPc` debe confiar en ese forwarder.

```bash
# Forwarder confiable configurado en Claim
cast call "$CLAIM" "trustedForwarder()(address)" --rpc-url "$SEPOLIA_RPC_URL"
cast call "$CLAIM" "isTrustedForwarder(address)(bool)" "$FORWARDER" --rpc-url "$SEPOLIA_RPC_URL"
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
CLAIM_ADMIN=$(cast call "$CLAIM" "admin()(address)" --rpc-url "$SEPOLIA_RPC_URL")
ARGS_CLAIM=$(cast abi-encode "constructor(address,address,uint256,address)" "$TOKEN" "$IDENTITY_REGISTRY_ADAPTER" "$CLAIM_AMOUNT" "$CLAIM_ADMIN")

forge verify-contract "$CLAIM" src/ClaimCLPc.sol:ClaimCLPc \
  --chain-id 11155111 \
  --constructor-args "$ARGS_CLAIM" \
  --verifier blockscout \
  --verifier-url "$BS_API" \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Forwarder `ERC2771Forwarder`:

```bash
ARGS_FWD=$(cast abi-encode "constructor(string)" "AdmapuForwarder")

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
