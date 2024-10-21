import { AssetType } from "./token-model";

export interface AssetStatistic {
  mwh: number;
  assetType: AssetType;
  redemptions: number;
  sells: number;
}
