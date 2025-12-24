# Development Roadmap

Este roadmap está pensado para avanzar en el desarrollo del proyecto de forma independiente. Cada "milestone" debería dejar el repo en estado _mergeable_ con tests.

Se asume lo siguiente:

- Solidity ^0.8.27
- OpenZeppelin 5.x
- Foundry
- Nombres de branches con prefijo tipo `feat/`, `fix/`, `chore/`, `docs/`, `tests/`
- Requerimientos de cada branch: **un** objetivo claro + tests + docs mínimos

## Milestone 0: Base reproducible

- `chore/tooling-foundry`: `foundry.toml` limpio, solc fijo en 0.8.27, `forge fmt`, `forge test`
- `chore/env-sepolia`: `.env.example` con scripts de deploy en ETH Sepolia y README de setup
- `test/ci`: Github actions con lint y tests mínimos
- `docs/poc-scope`: `docs/Poc-DefinitionOfDone.md` explicando qué significa PoC funcional en el contexto del proyecto

DoD: Cualquier persona clona el repo, corre `force test` y puede hacer deploy en ETH Sepolia utilizando scripts.

## Milesonte 1: On-chain core

- `feat/token-core`: CLPc ERC20 (OZ) + AccessControl (`DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `PAUSER_ROLE`)
- `feat/token-pausable`: pausa de transferencias (o pausa global, según diseño)
- `test/token-core`: tests de roles, minting, pause, revert reasons claras
- `docs/token-roles`: documentación de roles y política operacional

DoD: Token deployable, mint controlado, pausa funciona, tests.

## Milestone 2: ZK Gateway I

> Objetivo: demostrar "solo wallets verificadas pueden recibir/transar"

- `feat/verifier-interface`: interfaz IVerifier estable (ej. `isVerified(address) view returns(bool)` + `verify(...)`)
- `feat/verifier-mock`: MockVerifier con función admin para marcar verificación (para PoC)
- `feat/token-gating`: en token, aplicar gating:
  - bloquear transfer/transferFrom si `!isVerified(from)` o `!isVerified(to)`
  - definir excepción explícita (si aplica): mint a "program contracts" allowlisted
- `test/token-gating`: matriz de casos (verificado/no verificado; revert reasons)
- `docs/gating-policy`: reglas exactas (quién debe estar verificado y cuándo)

DoD: Con `MockVerifier` se puede probar el flujo completo en tests y en Sepolia.

## Milestone 3: ZK Gateway II

- `feat/verifier-production-skeleton`: contrato `ZKPassportVerifier` (stub) compatible con el esquema real (inputs + storage)
- `feat/verifier-upgrade-path`: estrategia de upgrade segura (si usas UUPS) o contrato “router” que apunta al verifier activo
- `test/verifier-integration`: tests con mock proof + compatibilidad de interfaz (que no rompa el token)
- `docs/zkpassport-integration`: documento corto con supuestos: qué prueba esperamos, qué campos, anti-replay, expiración

DoD: El token no cambia más; solo “enchufas” un verifier real más adelante.

## Milestone 4: Programa social mínimo (Subsidio adultos mayores)

- `feat/program-template`: plantilla `ProgramBase`  con budget, epoch/period y events
- `feat/program-v1`: `SeniorSubsidyProgram`
  - batch distribution para gas
  - solo a wallets verificadas
  - límites por período
- `test/program-v1`: happy path + límites + gating + roles
- `docs/program-v1`: cómo operar el programa (quién ejecuta, cada cuánto, parámetros)

DoD: El sistema ejecuta beneficios sociales on-chain con reglas claras.

## Milestone 5: Security and governance

> Objetivo: que se vea más _institutional_

- `feat/timelock-admin`: TimelockController para acciones críticas (mint params, allowlists, upgrades)
- `feat/multisig-ops`: guía para operar con multisig (Safe) + roles
- `test/gov-timelock`: tests de delays y ejecución
- `docs/threat-model-lite`: threat model - qué protege y qué no

DoD: Cambio de parámetros críticos solo vía timelock (delay) y multisig.

## Milestone 6: Demo PoC (UX mínima)

- `feat/webapp-minimal`: web (Next/React) con:
  - Conectar wallet
  - Verificar (mock → llama verifier)
  - Transferir CLPc (y mostrar errores de gating)
- `chore/deploy-demo-sepolia`: addresses en `deployments/sepolia.json` + script de seed/mint
- `docs/demo-runbook`: pasos exactos para demo

DoD: Demo en Sepolia en menos de 5 minutos.
