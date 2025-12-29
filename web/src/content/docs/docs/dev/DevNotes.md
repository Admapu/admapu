---
title: "Creación de mnemonic para usar wallets deterministicas"
head: []
---

```
Phrase: $MNEMONIC

Accounts:
- Account 0:
Address:     0x61422A92EE8361122fF156AA822045661a7595e8
Private key: 0x841a7d8876a90eace3357cd1ffbbde6ca2bf3a9d179cd6a9f03316beb4206926

```

A partir de lo anterior se derivarán las siguientes wallets (el index 0 es la wallet creada con la mnemonic):

- Deployer: index 1
- User_A: index 2
- User_B: index 3

El comando utulizado es:

```
cast wallet derive-private-key "$MNEMONIC" <index>
cast wallet address --private-key <private key del paso anterior>
```

Resultados:
DEPLOYER_INDEX: 2
DEPLOYER_ADDR: 0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A
DEPLOYER_PK: 0x02d660ca71b2716d15d7fdcbc9c5cb8a230489170bdde224c2a0f0824e4e930c

USER_A_INDEX: 2
USER_A_ADDR: 0xc30657e2Ebb1Bca9E00472D418aaD0D74a884B6e
USER_A_PK: 0xf1b90b2b2a3eeeeaab6fd6b4a5274c78283a0c53481891a60b97ee0354efde42

USER_B_INDEX: 3
USER_B_ADDR: 0x3fAA84317042E8C8aee32172bA1349629e836a5B
USER_B_PK: 0x408679ef82cb20e4bc580d7325ede94c10484ca92c243e355f72ac352a92656c


# Deploy a Sepolia
```
➜ forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PK --broadcast
[⠊] Compiling...
No files changed, compilation skipped
Script ran successfully.

== Return ==
verifier: address 0x0C581282aB9A577640764fE119ee464660e9eF1d
token: address 0x9FFd0AC2b8a563279cD6b2BaBd3224c397A66248

== Logs ==
  Admin: 0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A
  Verifier: 0x0C581282aB9A577640764fE119ee464660e9eF1d
  Token: 0x9FFd0AC2b8a563279cD6b2BaBd3224c397A66248

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 10.411607939 gwei

Estimated total gas used for script: 2882232

Estimated amount required: 0.030008669573239848 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x154b25087df284d316fd9eca45d3ffb32c2e057227dbdca854c4363b4f16a810
Contract Address: 0x0C581282aB9A577640764fE119ee464660e9eF1d
Block: 9859772
Paid: 0.002787107437508688 ETH (525894 gas * 5.299751352 gwei)


##### sepolia
✅  [Success] Hash: 0xcc8faf44a92e62ad63819fffc6aabe083c04e114a132ed365c395737efef0a52
Contract Address: 0x9FFd0AC2b8a563279cD6b2BaBd3224c397A66248
Block: 9859773
Paid: 0.008285495086170648 ETH (1691208 gas * 4.899157931 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.011072602523679336 ETH (2217102 gas * avg 5.099454641 gwei)


==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /home/boris/Code/clpc/code/broadcast/Deploy.s.sol/11155111/run-latest.json

Sensitive values saved to: /home/boris/Code/clpc/code/cache/Deploy.s.sol/11155111/run-latest.json

```

## Deploy del contrato ClaimCLPc
Deployer: 0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A
Deployed to: 0x8a9C3ea1BC2B08d358b1ddbD4e2C5244385D9438
Transaction hash: 0x6b04e78c6d52658beebc03702eeb105b64f31148b143c0ac2ccc3cb28d8574e6

Luego, usar el `Deployed to` como `CLAIM` en .env y darle permisos de "minter" al Claim, pero primero confirmamos:

```
➜ cast call $TOKEN "hasRole(bytes32,address)(bool)" $MINTER_ROLE $CLAIM --rpc-url "$SEPOLIA_RPC_URL"
false
```

Ahora le damos minter al Claim:

```
➜ cast send $TOKEN "grantRole(bytes32,address)" $MINTER_ROLE $CLAIM --rpc-url "$SEPOLIA_RPC_URL" --private-key "$DEPLOYER_PK"

blockHash            0x6cbe1d30a8a646358432cfe9ca8258bdef781cd5220042d498590310c769c253
blockNumber          9865916
contractAddress
cumulativeGasUsed    29250438
effectiveGasPrice    945043823
from                 0x7a64e4a47A4B1982bB1ab51D177a30E39f3B959A
gasUsed              51557
logs                 [{"address":"0x9ffd0ac2b8a563279cd6b2babd3224c397a66248","topics":["0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d","0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6","0x0000000000000000000000008a9c3ea1bc2b08d358b1ddbd4e2c5244385d9438","0x0000000000000000000000007a64e4a47a4b1982bb1ab51d177a30e39f3b959a"],"data":"0x","blockHash":"0x6cbe1d30a8a646358432cfe9ca8258bdef781cd5220042d498590310c769c253","blockNumber":"0x968abc","blockTimestamp":"0x6943d6ac","transactionHash":"0x367705568372e19eaa2689e1965b90bcb4f9236af502ea9c828746aa2d96d9ef","transactionIndex":"0x7b","logIndex":"0x427","removed":false}]
logsBloom            0x00000004000000000000000000000000000000000000000000000000000000000000000000000200200000000000004000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000001000000000000000000000002000000000000000000000000000000004000000010000000000000000000000000000000001000000000000000000001000000000000000000000000000100000000000000000001000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000
root
status               1 (success)
transactionHash      0x367705568372e19eaa2689e1965b90bcb4f9236af502ea9c828746aa2d96d9ef
transactionIndex     123
type                 2
blobGasPrice
blobGasUsed
to                   0x9FFd0AC2b8a563279cD6b2BaBd3224c397A66248

```

Y confirmamos otra vez:

```
➜ cast call $TOKEN "hasRole(bytes32,address)(bool)" $MINTER_ROLE $CLAIM --rpc-url "$SEPOLIA_RPC_URL"
true

```

Entonces, probamos el claim con usuario "reales". El usuario A está verificado, el B no.
(Nota: el usuario debe tener saldo para pagar el gas)

```
➜ cast send $CLAIM "claim()" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$USER_A_PK"

blockHash            0xafb4d422d1111ef440a35d690c8294862a97194cb98167c99c78515bf73a31cb
blockNumber          9865945
contractAddress
cumulativeGasUsed    45123343
effectiveGasPrice    533107244
from                 0xc30657e2Ebb1Bca9E00472D418aaD0D74a884B6e
gasUsed              88613
logs                 [{"address":"0x9ffd0ac2b8a563279cd6b2babd3224c397a66248","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000000000000000000000000000000000000000000000","0x000000000000000000000000c30657e2ebb1bca9e00472d418aad0d74a884b6e"],"data":"0x000000000000000000000000000000000000000000000000000000e8d4a51000","blockHash":"0xafb4d422d1111ef440a35d690c8294862a97194cb98167c99c78515bf73a31cb","blockNumber":"0x968ad9","blockTimestamp":"0x6943d814","transactionHash":"0x8e04b7e9cf91de746bb5352f1151ee3b08ae1a88321d72e96d6516d36c71eea4","transactionIndex":"0x9d","logIndex":"0x4be","removed":false},{"address":"0x9ffd0ac2b8a563279cd6b2babd3224c397a66248","topics":["0x6155cfd0fd028b0ca77e8495a60cbe563e8bce8611f0aad6fedbdaafc05d44a2","0x000000000000000000000000c30657e2ebb1bca9e00472d418aad0d74a884b6e"],"data":"0x000000000000000000000000000000000000000000000000000000e8d4a5100000000000000000000000000000000000000000000000000000000000000007e9000000000000000000000000000000000000000000000000000000e8da9af100","blockHash":"0xafb4d422d1111ef440a35d690c8294862a97194cb98167c99c78515bf73a31cb","blockNumber":"0x968ad9","blockTimestamp":"0x6943d814","transactionHash":"0x8e04b7e9cf91de746bb5352f1151ee3b08ae1a88321d72e96d6516d36c71eea4","transactionIndex":"0x9d","logIndex":"0x4bf","removed":false},{"address":"0x8a9c3ea1bc2b08d358b1ddbd4e2c5244385d9438","topics":["0xd8138f8a3f377c5259ca548e70e4c2de94f129f5a11036a15b69513cba2b426a","0x000000000000000000000000c30657e2ebb1bca9e00472d418aad0d74a884b6e"],"data":"0x000000000000000000000000000000000000000000000000000000e8d4a51000","blockHash":"0xafb4d422d1111ef440a35d690c8294862a97194cb98167c99c78515bf73a31cb","blockNumber":"0x968ad9","blockTimestamp":"0x6943d814","transactionHash":"0x8e04b7e9cf91de746bb5352f1151ee3b08ae1a88321d72e96d6516d36c71eea4","transactionIndex":"0x9d","logIndex":"0x4c0","removed":false}]
logsBloom            0x00000000000000000000000000000080000080400000000000000000000000000000000000000000000000000090000000000000000000040000000000000000000000000000000000000008000000000000001000001000000000000000000000000000020000000000008000000800000000000000000000000010000000000000000000000000000000000000004000000000000000000000000000010000000000000000000000000000000001000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000200001000000000200000000000000
root
status               1 (success)
transactionHash      0x8e04b7e9cf91de746bb5352f1151ee3b08ae1a88321d72e96d6516d36c71eea4
transactionIndex     157
type                 2
blobGasPrice
blobGasUsed
to                   0x8a9C3ea1BC2B08d358b1ddbD4e2C5244385D9438

```

Ahora con el usuario B (no verificado):

```
➜ cast send $CLAIM "claim()" --rpc-url "$SEPOLIA_RPC_URL" --private-key "$USER_B_PK"
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0xb12c8f910000000000000000000000003faa84317042e8c8aee32172ba1349629e836a5b": NotVerified(0x3fAA84317042E8C8aee32172bA1349629e836a5B)
```
