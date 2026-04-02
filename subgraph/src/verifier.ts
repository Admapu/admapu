import {
  AddressVerified,
  VerificationRevoked
} from "../generated/MockZKPassportVerifier/MockZKPassportVerifier";
import { RevocationEvent, VerificationEvent } from "../generated/schema";
import {
  chargeTransactionGasOnce,
  getOrCreateAccount,
  getOrCreateDailyMetric,
  getOrCreateGlobalMetric,
  getOrCreateHourlyMetric,
  makeEventId,
  syncBucketSnapshots
} from "./helpers";

export function handleAddressVerified(event: AddressVerified): void {
  let timestamp = event.block.timestamp;
  let account = getOrCreateAccount(event.params.account, timestamp);
  let global = getOrCreateGlobalMetric(timestamp);
  let hourly = getOrCreateHourlyMetric(timestamp);
  let daily = getOrCreateDailyMetric(timestamp);

  global.cumulativeVerificationEvents += 1;
  hourly.verifiedEvents += 1;
  hourly.netVerifiedDelta += 1;
  daily.verifiedEvents += 1;
  daily.netVerifiedDelta += 1;

  if (!account.currentVerified) {
    global.currentVerifiedUsers += 1;
    if (account.revocationCount > 0 && global.currentRevokedUsers > 0) {
      global.currentRevokedUsers -= 1;
    }
  }

  account.currentVerified = true;
  account.everVerified = true;
  account.verificationCount += 1;
  account.lastVerificationTimestamp = timestamp;
  account.updatedAt = timestamp;
  account.save();

  global.updatedAt = timestamp;
  global.save();
  syncBucketSnapshots(hourly, daily, global, timestamp);

  let verification = new VerificationEvent(makeEventId(event.transaction.hash, event.logIndex));
  verification.account = account.id;
  verification.timestamp = timestamp;
  verification.blockNumber = event.block.number;
  verification.transactionHash = event.transaction.hash;
  verification.save();

  chargeTransactionGasOnce(
    event.transaction.hash,
    event.receipt,
    event.transaction.gasPrice,
    timestamp,
    event.block.number
  );
}

export function handleVerificationRevoked(event: VerificationRevoked): void {
  let timestamp = event.block.timestamp;
  let account = getOrCreateAccount(event.params.account, timestamp);
  let global = getOrCreateGlobalMetric(timestamp);
  let hourly = getOrCreateHourlyMetric(timestamp);
  let daily = getOrCreateDailyMetric(timestamp);

  global.cumulativeRevocationEvents += 1;
  hourly.revokedEvents += 1;
  hourly.netVerifiedDelta -= 1;
  daily.revokedEvents += 1;
  daily.netVerifiedDelta -= 1;

  if (account.currentVerified && global.currentVerifiedUsers > 0) {
    global.currentVerifiedUsers -= 1;
  }
  global.currentRevokedUsers += 1;

  account.currentVerified = false;
  account.revocationCount += 1;
  account.lastRevocationTimestamp = timestamp;
  account.updatedAt = timestamp;
  account.save();

  global.updatedAt = timestamp;
  global.save();
  syncBucketSnapshots(hourly, daily, global, timestamp);

  let revocation = new RevocationEvent(makeEventId(event.transaction.hash, event.logIndex));
  revocation.account = account.id;
  revocation.timestamp = timestamp;
  revocation.blockNumber = event.block.number;
  revocation.transactionHash = event.transaction.hash;
  revocation.save();

  chargeTransactionGasOnce(
    event.transaction.hash,
    event.receipt,
    event.transaction.gasPrice,
    timestamp,
    event.block.number
  );
}
