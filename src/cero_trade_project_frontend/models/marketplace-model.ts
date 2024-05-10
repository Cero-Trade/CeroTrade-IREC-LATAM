import { AssetInfoModel } from "./token-model";
import { TokensICP } from "./transaction-model";

export interface MarketplaceInfo {
  tokenId: Text;
  lowerPriceICP: TokensICP;
  higherPriceICP: TokensICP;
  mwh: number;
  assetInfo: AssetInfoModel;
}

export interface MarketplaceSellersInfo {
  sellerId: string;
  tokenId: Text;
  priceICP: TokensICP;
  mwh: number;
  assetInfo: AssetInfoModel;
}