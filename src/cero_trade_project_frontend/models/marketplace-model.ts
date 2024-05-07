import { AssetInfoModel } from "./token-model";

export interface MarketplaceInfo {
  tokenId: Text;
  lowerPriceICP: number;
  higherPriceICP: number;
  mwh: number;
  assetInfo: AssetInfoModel;
}