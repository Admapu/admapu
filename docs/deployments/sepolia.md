# CLPc — Deploy en Ethereum Sepolia

Fecha: 2026-01-04  
Red: Ethereum Sepolia  
Chain ID: `11155111`

Para la mayoría de las direcciones estoy usando [ENS](https://ens.domains/) y, para faciltiar su uso, recomiendo usar [Blockscout](https://eth-sepolia.blockscout.com) como explorer ya que resuelve ENS automáticamente y EtherScan aun no soporta este feature en Sepolia.

La dirección es [admapu.eth](https://sepolia.app.ens.domains/admapu.eth).

## Direcciones (Sepolia)

**Admin / Deployer**
- ENS: `admin.admapu.eth`
- Address: `0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A`

**Verifier (MockZKPassportVerifier)**
- Address: `0x3835D6a584aC858C5762AC81E53fE8c5E38a87b7`
- Tx hash (deploy): `0xbe1b84cd0dc05c7060268ef685fa98462f5b5fed3f8c7db60b10381f55b63030`
- Block: `9981114`

**Token (CLPc)**
- Address: `0x39cFD0C6807568D68609E24A9907e5275Bd86379`
- Tx hash (deploy): `0x54ca0d6c0bdde0dd47898fc016c94cb66372c49ec804d21b9fd6052d9196809e`
- Block: `9981114`

## Etherscan

- Verifier: https://eth-sepolia.blockscout.com/address/0x3835D6a584aC858C5762AC81E53fE8c5E38a87b7
- Token:    https://eth-sepolia.blockscout.com/address/0x39cFD0C6807568D68609E24A9907e5275Bd86379

Txs:
- Deploy Verifier: https://eth-sepolia.blockscout.com/tx/0xbe1b84cd0dc05c7060268ef685fa98462f5b5fed3f8c7db60b10381f55b63030
- Deploy Token:    https://eth-sepolia.blockscout.com/tx/0x54ca0d6c0bdde0dd47898fc016c94cb66372c49ec804d21b9fd6052d9196809e

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
export VERIFIER="0x3835D6a584aC858C5762AC81E53fE8c5E38a87b7"
export TOKEN="0x39cFD0C6807568D68609E24A9907e5275Bd86379"
```
