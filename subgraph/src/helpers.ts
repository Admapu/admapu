import { BigInt, Bytes, ethereum } from "@graphprotocol/graph-ts";
import {
  Account,
  DailyMetric,
  GlobalMetric,
  HourlyMetric,
  ProcessedTransaction
} from "../generated/schema";

let GLOBAL_ID = "current";
let ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
let ONE = BigInt.fromI32(1);
let ZERO = BigInt.zero();
let HOUR = BigInt.fromI32(3600);
let DAY = BigInt.fromI32(86400);

export function getOrCreateAccount(accountId: Bytes, timestamp: BigInt): Account {
  let account = Account.load(accountId);
  if (account == null) {
    account = new Account(accountId);
    account.currentVerified = false;
    account.everVerified = false;
    account.verificationCount = 0;
    account.revocationCount = 0;
    account.claimed = false;
    account.claimCount = 0;
    account.totalClaimed = ZERO;
    account.createdAt = timestamp;
  }

  account.updatedAt = timestamp;
  return account;
}

export function getOrCreateGlobalMetric(timestamp: BigInt): GlobalMetric {
  let metric = GlobalMetric.load(GLOBAL_ID);
  if (metric == null) {
    metric = new GlobalMetric(GLOBAL_ID);
    metric.currentVerifiedUsers = 0;
    metric.currentRevokedUsers = 0;
    metric.cumulativeVerificationEvents = 0;
    metric.cumulativeRevocationEvents = 0;
    metric.clpcTransferCount = ZERO;
    metric.clpcTransferVolume = ZERO;
    metric.clpcMintCount = ZERO;
    metric.clpcMintVolume = ZERO;
    metric.clpcBurnCount = ZERO;
    metric.clpcBurnVolume = ZERO;
    metric.claimCount = ZERO;
    metric.claimVolume = ZERO;
    metric.gasSpentWei = ZERO;
  }

  metric.updatedAt = timestamp;
  return metric;
}

function getBucketStart(timestamp: BigInt, bucketSize: BigInt): BigInt {
  return timestamp.div(bucketSize).times(bucketSize);
}

export function getOrCreateHourlyMetric(timestamp: BigInt): HourlyMetric {
  let bucketStart = getBucketStart(timestamp, HOUR);
  let id = bucketStart.toString();
  let metric = HourlyMetric.load(id);

  if (metric == null) {
    metric = new HourlyMetric(id);
    metric.bucketStart = bucketStart;
    metric.verifiedEvents = 0;
    metric.revokedEvents = 0;
    metric.netVerifiedDelta = 0;
    metric.clpcTransferCount = ZERO;
    metric.clpcTransferVolume = ZERO;
    metric.clpcMintCount = ZERO;
    metric.clpcMintVolume = ZERO;
    metric.clpcBurnCount = ZERO;
    metric.clpcBurnVolume = ZERO;
    metric.claimCount = ZERO;
    metric.claimVolume = ZERO;
    metric.gasSpentWei = ZERO;
    metric.currentVerifiedUsers = 0;
    metric.currentRevokedUsers = 0;
  }

  metric.updatedAt = timestamp;
  return metric;
}

export function getOrCreateDailyMetric(timestamp: BigInt): DailyMetric {
  let bucketStart = getBucketStart(timestamp, DAY);
  let id = bucketStart.toString();
  let metric = DailyMetric.load(id);

  if (metric == null) {
    metric = new DailyMetric(id);
    metric.bucketStart = bucketStart;
    metric.verifiedEvents = 0;
    metric.revokedEvents = 0;
    metric.netVerifiedDelta = 0;
    metric.clpcTransferCount = ZERO;
    metric.clpcTransferVolume = ZERO;
    metric.clpcMintCount = ZERO;
    metric.clpcMintVolume = ZERO;
    metric.clpcBurnCount = ZERO;
    metric.clpcBurnVolume = ZERO;
    metric.claimCount = ZERO;
    metric.claimVolume = ZERO;
    metric.gasSpentWei = ZERO;
    metric.currentVerifiedUsers = 0;
    metric.currentRevokedUsers = 0;
  }

  metric.updatedAt = timestamp;
  return metric;
}

export function syncBucketSnapshots(
  hourly: HourlyMetric,
  daily: DailyMetric,
  global: GlobalMetric,
  timestamp: BigInt
): void {
  hourly.currentVerifiedUsers = global.currentVerifiedUsers;
  hourly.currentRevokedUsers = global.currentRevokedUsers;
  hourly.updatedAt = timestamp;
  hourly.save();

  daily.currentVerifiedUsers = global.currentVerifiedUsers;
  daily.currentRevokedUsers = global.currentRevokedUsers;
  daily.updatedAt = timestamp;
  daily.save();
}

export function chargeTransactionGasOnce(
  txHash: Bytes,
  receipt: ethereum.TransactionReceipt | null,
  gasPrice: BigInt,
  timestamp: BigInt,
  blockNumber: BigInt
): void {
  if (receipt == null) {
    return;
  }

  let processed = ProcessedTransaction.load(txHash);
  if (processed != null) {
    return;
  }

  let gasSpentWei = receipt.gasUsed.times(gasPrice);

  processed = new ProcessedTransaction(txHash);
  processed.gasSpentWei = gasSpentWei;
  processed.blockNumber = blockNumber;
  processed.timestamp = timestamp;
  processed.save();

  let global = getOrCreateGlobalMetric(timestamp);
  let hourly = getOrCreateHourlyMetric(timestamp);
  let daily = getOrCreateDailyMetric(timestamp);

  global.gasSpentWei = global.gasSpentWei.plus(gasSpentWei);
  global.updatedAt = timestamp;
  global.save();

  hourly.gasSpentWei = hourly.gasSpentWei.plus(gasSpentWei);
  daily.gasSpentWei = daily.gasSpentWei.plus(gasSpentWei);
  syncBucketSnapshots(hourly, daily, global, timestamp);
}

export function makeEventId(txHash: Bytes, logIndex: BigInt): string {
  return txHash.toHexString() + "-" + logIndex.toString();
}

export function isZeroAddress(address: Bytes): boolean {
  return address.toHexString() == ZERO_ADDRESS;
}

export function incrementBigInt(value: BigInt): BigInt {
  return value.plus(ONE);
}
