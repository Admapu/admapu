# [HIGH] Divergence risk: Claim verifier source vs CLPc identity source

## Summary
`ClaimCLPc` previously validated eligibility via a verifier interface (`isVerified`) while `CLPc` transfer/mint gating used `IIdentityRegistry.isVerifiedChilean`.

This split can create inconsistent eligibility decisions across contracts.

## Affected components
- `src/ClaimCLPc.sol` (before this fix)
- `src/CLPc.sol`

## Exploit / verification steps (reproduce issue)
1. Deploy `CLPc` with identity source A.
2. Deploy `ClaimCLPc` with verifier source B.
3. Mark user as verified in source B but not in source A.
4. User can call `claim()` successfully (old behavior) and receive minted tokens to wallet.
5. Depending on token gating state/transfers, funds may become operationally inconsistent and policies diverge.

Even when direct theft is not trivial, this is a high-risk policy-bypass surface and a major governance/ops hazard.

## Remediation in this PR
- `ClaimCLPc` now depends on `IIdentityRegistryView` and checks:
  - `isVerifiedChilean(msg.sender)`
- This aligns claim eligibility with the same identity model used by `CLPc`.

## Deploy / migration steps
1. Deploy new `ClaimCLPc` pointing to the same identity registry used by `CLPc`.
2. Grant `MINTER_ROLE` to the new claim contract.
3. Revoke `MINTER_ROLE` from old claim contract (if granted).
4. Update frontend/backend env vars to new claim address.

## Post-remediation checks
- If user is verified in registry: `claim()` succeeds once.
- If user is not verified in registry: `claim()` reverts `NotVerified`.
- Ensure only new claim contract keeps mint permission.
