import { AssetInfoModel } from "./token-model";
import { TokensICP } from "./transaction-model";

export interface MarketplaceInfo {
  tokenId: string;
  lowerPriceE8S: TokensICP;
  higherPriceE8S: TokensICP;
  mwh: number;
  assetInfo: AssetInfoModel;
}

export interface MarketplaceSellersInfo {
  sellerId: string;
  tokenId: string;
  priceE8S: TokensICP;
  mwh: number;
  assetInfo: AssetInfoModel;
}