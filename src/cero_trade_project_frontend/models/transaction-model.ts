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
}
export type TxTypeDef = keyof typeof TxType

export interface TransactionInfo {
  transactionId: string;
  blockHash: number;
  from: string;
  to?: string;
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
  txIndex: number;
  from: string;
  to?: string;
  assetInfo?: AssetInfoModel;
  txType: TxTypeDef;
  tokenAmount: number;
  priceE8S?: TokensICP;
  date: Date;
  method: TxMethodDef;
  redemptionPdf?: File;
}