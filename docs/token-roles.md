# CLPc — Roles y Política Operacional

Este documento describe los **roles on-chain**, sus responsabilidades y la **política operacional** del contrato `CLPc`.

El objetivo es dejar explícito **quién puede hacer qué**, bajo qué condiciones, y cómo se espera que estos roles sean operados en un entorno real (POC serio).

---

## 1. Visión general

El contrato `CLPc` utiliza `AccessControl` de OpenZeppelin para gestionar permisos críticos, tales como:

- Emisión de tokens (minting)
- Pausa de la emisión
- Administración de roles
- Configuración de parámetros sensibles

El sistema prioriza un control estricto de emisión con capacidad de detener la emisión ante incidentes. Además, se asegura el cumplimiento mediante verificación de identidad (ZK-gated transfers)

---

## 2. Roles definidos

### 2.1 DEFAULT_ADMIN_ROLE

**Descripción**
- Rol administrador principal del contrato.
- Puede otorgar y revocar todos los demás roles.

**Permisos**
- `grantRole(...)`
- `revokeRole(...)`
- Configuración de parámetros críticos (ej: verificador de identidad)

**Asignación inicial**
- Cuenta que ejecuta el deploy del contrato.

**Política operacional**
- Debe ser transferido a:
  - Multisig, DAO o entidad institucional
- No debe usarse para operaciones diarias.
- Idealmente protegido por timelock (fuera del scope de M1).

---

### 2.2 MINTER_ROLE

**Descripción**
- Autoriza la emisión de nuevos tokens CLPc.

**Permisos**
- `mint(address to, uint256 amount)`
- `mintBatch(address[] to, uint256[] amount)`

**Restricciones**
- Sujeto a:
  - Límite máximo de emisión anual
  - Reglas de verificación del receptor
  - Estado global de pausa de minting

**Asignación típica**
- Entidad emisora (programas públicos, subsidios, recompensas, etc.)

**Política operacional**
- Debe ser concedido solo a contratos o cuentas auditadas.
- Puede existir más de un minter activo.
- Debe revocarse inmediatamente ante compromiso de claves.

---

### 2.3 PAUSER_ROLE

**Descripción**
- Permite pausar y reanudar la emisión de tokens.

**Permisos**
- `pauseMinting()`
- `unpauseMinting()`

**Importante (M1)**
> La pausa **solo afecta al minting**.  
> **Las transferencias no se pausan** en este milestone.

**Asignación típica**
- Entidad de respuesta a incidentes
- Multisig de emergencia
- Comité de gobernanza reducido

**Política operacional**
- Uso exclusivo en situaciones excepcionales:
  - Bug crítico
  - Emisión incorrecta
  - Incidente de seguridad
- Toda activación debería quedar registrada y documentada off-chain.

---

## 3. Reglas de transferencia (compliance)

En M1, las transferencias de CLPc están sujetas a verificación:

- El **emisor** debe estar verificado
- El **receptor** debe estar verificado

Si cualquiera de las dos condiciones falla:
- La transferencia revierte

Estas reglas son independientes del sistema de pausa de minting.

---

## 4. Escenarios operacionales comunes

### Emisión normal
1. Admin otorga `MINTER_ROLE`
2. Minter ejecuta `mint` o `mintBatch`
3. Se valida:
   - Límite anual
   - Verificación del receptor
   - Estado de pausa

### Incidente de emisión
1. Pauser ejecuta `pauseMinting`
2. Se detiene toda nueva emisión
3. Se analiza el incidente
4. Admin decide acciones correctivas
5. Pauser ejecuta `unpauseMinting`

---

## 5. Limitaciones conocidas (M1)

Las siguientes capacidades **no están incluidas** en este milestone:

- Pausa global de transferencias
- Timelocks on-chain
- Gobernanza DAO
- Upgradeability
- Slashing o penalizaciones

Estas funcionalidades serán evaluadas en milestones posteriores.

---

## 6. Relación con tests

Las siguientes garantías están cubiertas por tests automatizados:

- Solo admin puede otorgar roles
- Solo minters pueden emitir
- El minting puede pausarse
- Usuarios no autorizados no pueden emitir ni pausar
- Transferencias sin verificación fallan

---

## 7. Objetivo del diseño

Este esquema busca demostrar que es posible:
- Emitir un token con control institucional
- Mantener garantías de cumplimiento
- Conservar propiedades de soberanía y verificabilidad on-chain

Todo esto sin comprometer la simplicidad ni la auditabilidad del sistema.

---

