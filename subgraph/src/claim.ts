import { Claimed } from "../generated/ClaimCLPc/ClaimCLPc";
import { ClaimEvent } from "../generated/schema";
import {
  chargeTransactionGasOnce,
  getOrCreateAccount,
  getOrCreateDailyMetric,
  getOrCreateGlobalMetric,
  getOrCreateHourlyMetric,
  incrementBigInt,
  makeEventId,
  syncBucketSnapshots
} from "./helpers";

export function handleClaimed(event: Claimed): void {
  let timestamp = event.block.timestamp;
  let account = getOrCreateAccount(event.params.user, timestamp);
  let global = getOrCreateGlobalMetric(timestamp);
  let hourly = getOrCreateHourlyMetric(timestamp);
  let daily = getOrCreateDailyMetric(timestamp);
  let amount = event.params.amount;

  account.claimed = true;
  account.claimCount += 1;
  account.totalClaimed = account.totalClaimed.plus(amount);
  account.updatedAt = timestamp;
  account.save();

  global.claimCount = incrementBigInt(global.claimCount);
  global.claimVolume = global.claimVolume.plus(amount);
  global.updatedAt = timestamp;
  global.save();

  hourly.claimCount = incrementBigInt(hourly.claimCount);
  hourly.claimVolume = hourly.claimVolume.plus(amount);
  daily.claimCount = incrementBigInt(daily.claimCount);
  daily.claimVolume = daily.claimVolume.plus(amount);
  syncBucketSnapshots(hourly, daily, global, timestamp);

  let claim = new ClaimEvent(makeEventId(event.transaction.hash, event.logIndex));
  claim.account = account.id;
  claim.amount = amount;
  claim.timestamp = timestamp;
  claim.blockNumber = event.block.number;
  claim.transactionHash = event.transaction.hash;
  claim.save();

  chargeTransactionGasOnce(
    event.transaction.hash,
    event.receipt,
    event.transaction.gasPrice,
    timestamp,
    event.block.number
  );
}
