import { AssetInfoModel } from "./token-model";
import { UserProfileModel } from "./user-profile-model";

export type TokensICP = { e8s: number };

export enum TxMethod {
  blockchainTransfer = 'blockchainTransfer',
  bankTransfer = 'bankTransfer',
}
export type TxMethodDef = keyof typeof TxMethod

export enum TxType {
  transfer = 'transfer',
  redemption = 'redemption',
}
export type TxTypeDef = keyof typeof TxType

export interface TransactionInfo {
  transactionId: string;
  blockHash: number;
  from: string;
  to: string;
  tokenId: string;
  txType: TxTypeDef;
  tokenAmount: number;
  priceICP: TokensICP;
  date: Date;
  method: TxMethodDef;
}

export interface TransactionHistoryInfo {
  transactionId: string;
  blockHash: number;
  recipentProfile?: UserProfileModel;
  assetInfo: AssetInfoModel;
  txType: TxTypeDef;
  tokenAmount: number;
  priceICP: TokensICP;
  date: Date;
  method: TxMethodDef;
}