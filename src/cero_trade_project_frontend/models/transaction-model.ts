export type TokensICP = { e8s: number };

export type TxType = "transfer"|"redemption";

export interface TransactionInfo {
  transactionId: string;
  blockHash: number;
  from: string;
  to: string;
  tokenId: string;
  txType: TxType;
  tokenAmount: number;
  priceICP: TokensICP;
}