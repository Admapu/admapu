# [CRITICAL] Interface mismatch between CLPc identity registry and deployed verifier

## Summary
`CLPc` expects an `IIdentityRegistry` implementation and calls:

- `isVerifiedChilean(address)`

However, the previous deployment script instantiated `MockZKPassportVerifier` directly and passed it to `CLPc`. That verifier exposes:

- `isVerified(address)`

This mismatch can make identity checks revert at runtime, effectively breaking minting/transfers that depend on verification.

## Affected components
- `src/CLPc.sol`
- `src/mocks/MockZKPassportVerifier.sol`
- `script/Deploy.s.sol` (before this fix)

## Exploit / verification steps (reproduce issue)
1. Deploy old version (`Deploy.s.sol`) that sets `CLPc(identityRegistry = MockZKPassportVerifier)`.
2. Mark a user as verified in the verifier (`verify(user)`).
3. Attempt to mint or transfer in `CLPc` where verification is required.
4. Observe failure because `CLPc` calls `isVerifiedChilean(address)` on a contract that does not implement it.

## Remediation in this PR
This PR adds an adapter:
- `src/ZKPassportIdentityRegistryAdapter.sol`

The adapter implements `IIdentityRegistry.isVerifiedChilean(address)` and forwards to `IZKPassportVerifier.isVerified(address)`.

Deployment flow is updated:
1. Deploy `MockZKPassportVerifier`.
2. Deploy `ZKPassportIdentityRegistryAdapter(verifier)`.
3. Deploy `CLPc(identityRegistry = adapter)`.

## Deploy / migration steps
1. Deploy the new contracts with updated `Deploy.s.sol`.
2. Update environment/config values to point to:
   - new `VERIFIER`
   - new `IDENTITY_REGISTRY_ADAPTER`
   - new `TOKEN`
3. Re-run smoke checks:
   - verify user in verifier
   - `canReceive(user)` in token
   - mint to verified user
   - transfer between verified users
4. Deprecate old token deployment (document as unsafe/incompatible).

## Post-remediation checks
- `CLPc.canReceive(verifiedUser) == true`
- `mint(verifiedUser, amount)` succeeds
- transfer verified -> verified succeeds
- transfer to unverified reverts with `UnverifiedRecipient`
