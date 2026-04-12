# TransportBenefit - Tradeoff temporal de elegibilidad

## Decisión actual

Para el PoC actual, `TransportBenefit` **no** lee la elegibilidad de transporte escolar desde el registry de identidad compartido que usa `CLPc`.

En su lugar:

- La verificación de ciudadanía chilena sigue leyéndose desde el registry compartido mediante `isVerifiedChilean(address)`.
- La elegibilidad de transporte escolar se almacena como una allowlist interna dentro de `TransportBenefit`.
- El admin puede gestionar esa allowlist mediante:
  - `setEligible(address,bool)`
  - `setEligibleBatch(address[],bool)`

## Por qué se tomó esta decisión

El adapter de registry desplegado actualmente en Sepolia (`ZKPassportIdentityRegistryAdapter`) solo expone:

- `isVerifiedChilean(address)`

No expone un atributo específico de transporte como:

- `isSchoolTransport(address)`

Si `TransportBenefit` dependiera hoy de ese método, el contrato no podría desplegarse sobre la configuración actual de Sepolia sin migrar primero `CLPc` a una implementación de registry más rica.

Como `CLPc` protege los cambios de registry con un timelock de 2 días, esa migración ralentizaría las pruebas y la iteración operativa.

## Tradeoff

Esta decisión permite desplegar el nuevo beneficio de inmediato, pero introduce una divergencia arquitectónica temporal:

- `CLPc` usa el registry de identidad compartido como su fuente de verdad.
- `TransportBenefit` usa:
  - el registry compartido para verificar ciudadanía chilena
  - su propio storage para la elegibilidad de transporte escolar

Esto significa que el programa de transporte todavía no usa un único registry compartido para todas las dimensiones de elegibilidad.

## Perfil de riesgo

Para un PoC, esto es aceptable si se trata como temporal y se documenta con claridad.

Riesgos principales:

- deriva de elegibilidad entre el contrato del beneficio y cualquier futuro registry público
- sobrecarga administrativa adicional para mantener actualizada la allowlist de transporte
- posible confusión si los operadores asumen que toda la elegibilidad proviene del registry compartido

## Dirección futura planificada

El diseño deseado a largo plazo es:

- mantener `CLPc` y los contratos de beneficios conectados a la misma fuente de identidad compartida
- sacar la elegibilidad de transporte fuera del contrato del beneficio
- reemplazar la allowlist interna por una fuente real de elegibilidad de transporte
  - un registry on-chain más rico
  - o una ruta verifier/adapter que exponga esa elegibilidad de forma segura

En ese punto, `TransportBenefit` debería simplificarse para consumir la fuente de elegibilidad compartida en lugar de mantener la suya propia.

## Links relacionados

- [Github issue](https://github.com/Admapu/admapu/issues/29)
