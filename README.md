# Admapu

**Admapu** es el conjunto de leyes, tradiciones, normas y ética ancestrales que rigen la vida y la interacción con la naturaleza y la comunidad. Seguir el admapu es lo que asegura el _küme mongen_ (buen vivir). No hay un "protector" del admapu como tal, sino que su cumplimiento es vigilado colectivamente y su transgresión puede traer consecuencias negativas para la comunidad.

# Proyecto
Admapu es el _code name_ de CLPc, una prueba de concepto (PoC) de una stablecoin ERC-20 diseñada para ser utilizada exclusivamente por ciudadanos chilenos, donde la elegibilidad se demuestra on-chain mediante un verificador de identidad externo basado en Zero-Knowledge.

Este repositorio contiene los smart contracts y el tooling necesario para deployar y probar CLPc en Ethereum Sepolia utilizando Foundry.

⚠️ Importante: Este proyecto es experimental, no está listo para producción, no tiene fines de lucro, y busca servir como demostración técnica y conceptual que eventualmente podría ser extendida o adoptada por una institución pública.

## Conceptos clave
- ERC‑20 con identidad: solo wallets verificadas pueden recibir o transferir CLPc.
- Verificación externa: el token delega completamente la validación de identidad a un contrato verificador.
- Límite anual de emisión: el minting está acotado por año para controlar el suministro.
- Privacidad por diseño: no se almacena información personal on‑chain; solo checks booleanos de elegibilidad.

## Estructura del repositorio

```
.
├── src/
│ ├── CLPc.sol # Token ERC‑20 con transferencias restringidas por ZK
│ ├── IZKPassportVerifier.sol # Interfaz del verificador de identidad
│ ├── ClaimCLPc.sol # Contrato de claim único por wallet
│ └── mocks/
│ └── MockZKPassportVerifier.sol # Verificador mock (solo testing en Sepolia)
│
├── script/
│ └── Deploy.s.sol # Scripts de deployment
│
├── DevNotes.md # Notas detalladas de desarrollo y pruebas
├── README.md # Este archivo
└── foundry.toml
```

### Smart contracts (alto nivel)
- `CLPc.sol`: Implementa el token ERC-20 con lógica para restringir transferencias a wallets verificadas.
  - Token ERC‑20 con 8 decimales.
  - Minting y transferencias permitidas solo a direcciones verificadas.
  - Límite anual de emisión (MAX_ANNUAL_SUPPLY).
  - Control de acceso basado en roles (admin, minter, pauser, program).
- `IZKPassportVerifier.sol`: Interfaz para el contrato verificador de identidad externo.
  - Interfaz mínima usada por el token.
  - Define la función `isVerified(address user)` que retorna si una wallet está verificada.
  - Permite integración con cualquier verificador que implemente esta interfaz.
  - Abstrae la lógica de verificación de identidad (en producción validaría pruebas ZK).
- `MockZKPassportVerifier.sol`: Implementación mock del verificador de identidad.
  - Usado solo en Sepolia para pruebas.
  - Permite marcar direcciones como verificadas o no verificadas manualmente.
  - Incluye flags de edad para demostrar lógica de elegibilidad (18+, 65+).
- `ClaimCLPc.sol`: Contrato para reclamar una cantidad fija de CLPc una sola vez por wallet.
  - Permite a usuarios elegibles reclamar una cantidad predefinida de CLPc.
  - Verifica elegibilidad usando el verificador de identidad.
  - Registra wallets que ya han reclamado para evitar múltiples claims.

## Notas de diseño
- El token no almacena datos de identidad.
- La lógica de verificación es externa y reemplazable.
- Los contratos mock son exclusivos para Sepolia.
- La arquitectura es modular y permite:
  - Integración futura de pruebas ZK reales
  - Verificadores administrados por entidades públicas
  - Programas sociales con lógica propia

## Estado del proyecto
- ✅ Lógica base del token implementada
- ✅ Deploy funcional en Sepolia
- ✅ Minting y transferencias restringidas por identidad
- ✅ Mecanismo de claim único
- ⏳ Verificador ZK real (producción)
- ⏳ Gobernanza / DAO


## Publicaciones
- [Blog personal](https://borisquiroz.dev/posts/chilean-stable-coin/)
- [LinkedIn](https://www.linkedin.com/pulse/c%C3%B3mo-podr%C3%ADa-una-stablecoin-basada-en-identidad-el-acceso-quiroz-zyzte/?trackingId=1j4%2FUTh%2BQFuDWYJbkd%2BobA%3D%3D)

## Licencia
MIT
