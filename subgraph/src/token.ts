import { Transfer, TokensMinted } from "../generated/CLPc/CLPc";
import { TokenMintEvent, TokenTransferEvent } from "../generated/schema";
import {
  chargeTransactionGasOnce,
  getOrCreateDailyMetric,
  getOrCreateGlobalMetric,
  getOrCreateHourlyMetric,
  incrementBigInt,
  isZeroAddress,
  makeEventId,
  syncBucketSnapshots
} from "./helpers";

export function handleTransfer(event: Transfer): void {
  let timestamp = event.block.timestamp;
  let global = getOrCreateGlobalMetric(timestamp);
  let hourly = getOrCreateHourlyMetric(timestamp);
  let daily = getOrCreateDailyMetric(timestamp);
  let amount = event.params.value;

  let transferType = "TRANSFER";
  if (isZeroAddress(event.params.from)) {
    transferType = "MINT";
    global.clpcMintCount = incrementBigInt(global.clpcMintCount);
    global.clpcMintVolume = global.clpcMintVolume.plus(amount);
    hourly.clpcMintCount = incrementBigInt(hourly.clpcMintCount);
    hourly.clpcMintVolume = hourly.clpcMintVolume.plus(amount);
    daily.clpcMintCount = incrementBigInt(daily.clpcMintCount);
    daily.clpcMintVolume = daily.clpcMintVolume.plus(amount);
  } else if (isZeroAddress(event.params.to)) {
    transferType = "BURN";
    global.clpcBurnCount = incrementBigInt(global.clpcBurnCount);
    global.clpcBurnVolume = global.clpcBurnVolume.plus(amount);
    hourly.clpcBurnCount = incrementBigInt(hourly.clpcBurnCount);
    hourly.clpcBurnVolume = hourly.clpcBurnVolume.plus(amount);
    daily.clpcBurnCount = incrementBigInt(daily.clpcBurnCount);
    daily.clpcBurnVolume = daily.clpcBurnVolume.plus(amount);
  } else {
    global.clpcTransferCount = incrementBigInt(global.clpcTransferCount);
    global.clpcTransferVolume = global.clpcTransferVolume.plus(amount);
    hourly.clpcTransferCount = incrementBigInt(hourly.clpcTransferCount);
    hourly.clpcTransferVolume = hourly.clpcTransferVolume.plus(amount);
    daily.clpcTransferCount = incrementBigInt(daily.clpcTransferCount);
    daily.clpcTransferVolume = daily.clpcTransferVolume.plus(amount);
  }

  global.updatedAt = timestamp;
  global.save();
  syncBucketSnapshots(hourly, daily, global, timestamp);

  let transfer = new TokenTransferEvent(makeEventId(event.transaction.hash, event.logIndex));
  transfer.from = event.params.from;
  transfer.to = event.params.to;
  transfer.amount = amount;
  transfer.transferType = transferType;
  transfer.timestamp = timestamp;
  transfer.blockNumber = event.block.number;
  transfer.transactionHash = event.transaction.hash;
  transfer.save();

  chargeTransactionGasOnce(
    event.transaction.hash,
    event.receipt,
    event.transaction.gasPrice,
    timestamp,
    event.block.number
  );
}

export function handleTokensMinted(event: TokensMinted): void {
  let mintEvent = new TokenMintEvent(makeEventId(event.transaction.hash, event.logIndex));
  mintEvent.to = event.params.to;
  mintEvent.amount = event.params.amount;
  mintEvent.year = event.params.year;
  mintEvent.totalMintedThisYear = event.params.totalMintedThisYear;
  mintEvent.timestamp = event.block.timestamp;
  mintEvent.blockNumber = event.block.number;
  mintEvent.transactionHash = event.transaction.hash;
  mintEvent.save();

  chargeTransactionGasOnce(
    event.transaction.hash,
    event.receipt,
    event.transaction.gasPrice,
    event.block.timestamp,
    event.block.number
  );
}
