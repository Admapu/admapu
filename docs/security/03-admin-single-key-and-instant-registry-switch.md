# [HIGH] Single-key admin + instant identity-registry switch

## Summary
Before this fix, `DEFAULT_ADMIN_ROLE` could switch `identityRegistry` instantly via `setIdentityRegistry`.

If admin key is compromised (or misused), attacker can point `CLPc` to a malicious registry and bypass identity policy immediately.

## Affected component
- `src/CLPc.sol` (pre-fix behavior)

## Exploit / verification steps (old behavior)
1. Obtain/assume compromised admin key (or insider misuse).
2. Deploy malicious registry contract implementing `isVerifiedChilean(address)` and returning `true` for attacker wallets.
3. Call `setIdentityRegistry(maliciousRegistry)`.
4. Mint/transfer policy now trusts malicious source immediately.

## Remediation in this PR
Adds timelock flow for identity registry changes:
- `setIdentityRegistry(newRegistry)` now **schedules** update (2 days delay)
- `executeIdentityRegistryUpdate()` applies after ETA
- `cancelIdentityRegistryUpdate()` can cancel pending change

This does not eliminate admin risk, but adds detection/reaction window before policy source flips.

## Deploy / migration steps
1. Deploy new `CLPc` contract version.
2. Re-grant operational roles (`MINTER_ROLE`, `PAUSER_ROLE`, `PROGRAM_ROLE`) as needed.
3. Update integrations (frontend/backends/scripts) to new token address.
4. Optionally move admin role to multisig (recommended).

## Post-remediation checks
- Calling `setIdentityRegistry(new)` should only schedule.
- Early call to `executeIdentityRegistryUpdate()` must revert with `IdentityRegistryUpdateNotReady`.
- After delay, execute succeeds and emits `IdentityRegistryUpdated`.
- `cancelIdentityRegistryUpdate()` clears pending update.
