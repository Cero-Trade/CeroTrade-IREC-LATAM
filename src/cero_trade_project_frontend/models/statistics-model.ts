import { AssetType } from "./token-model";
import { TokensICP } from "./transaction-model";

export interface AssetStatistic {
  mwh: number;
  assetType: AssetType;
  redemptions: number;
  sells: number;
  priceE8STrend: TokensICP;
}
