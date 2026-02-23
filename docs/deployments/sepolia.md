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
- Address: `0xe1c2dB0ea79f8b91991aC789E32A35E39D7d1fF7`

## Blockscout links

- Verifier: https://eth-sepolia.blockscout.com/address/0xD51F4F3D2c35E51FD4Fda03D4Ae8A251801C9c94
- IdentityRegistryAdapter: https://eth-sepolia.blockscout.com/address/0xcF8aFab2abFBcAD243AF1928a329BA566f2ADe21
- Token:    https://eth-sepolia.blockscout.com/address/0xfb43d4e4dBB4c444e7Dcd73A86e836EC7607f553
- Claim:    https://eth-sepolia.blockscout.com/address/0xe1c2dB0ea79f8b91991aC789E32A35E39D7d1fF7

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
export CLAIM="0xe1c2dB0ea79f8b91991aC789E32A35E39D7d1fF7"
```
