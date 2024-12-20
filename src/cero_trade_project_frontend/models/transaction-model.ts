import { Principal } from "@dfinity/principal";
import { AssetInfoModel } from "./token-model";

export type TokensICP = number;
export type Tokens = { e8s: number };

export enum TxMethod {
  blockchainTransfer = 'blockchainTransfer',
  bankTransfer = 'bankTransfer',
}
export type TxMethodDef = keyof typeof TxMethod

export enum TxType {
  putOnSale = 'putOnSale',
  purchase = 'purchase',
  takeOffMarketplace = 'takeOffMarketplace',
  redemption = 'redemption',
  burn = 'burn',
  mint = 'mint',
}
export type TxTypeDef = keyof typeof TxType

export interface TransactionInfo {
  transactionId: string;
  tokenTxIndex: string;
  comissionTxHash?: string;
  ledgerTxHash?: string;
  from: { principal: Principal; name: string };
  to?: { principal: Principal; name: string };
  tokenId: string;
  txType: TxTypeDef;
  tokenAmount: number;
  priceE8S?: TokensICP;
  date: Date;
  method: TxMethodDef;
  redemptionPdf?: File;
}

export interface TransactionHistoryInfo {
  transactionId: string;
  tokenTxIndex: string;
  comissionTxHash?: string;
  ledgerTxHash?: string;
  from: { principal: Principal; name: string };
  to?: { principal: Principal; name: string };
  assetInfo?: AssetInfoModel;
  txType: TxTypeDef;
  tokenAmount: number;
  priceE8S?: TokensICP;
  date: Date;
  method: TxMethodDef;
  redemptionPdf?: File;
}