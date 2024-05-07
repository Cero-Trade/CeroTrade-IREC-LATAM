import { AssetInfoModel } from "./token-model";
import { TokensICP } from "./transaction-model";
import { UserProfileModel } from "./user-profile-model";

export interface MarketplaceInfo {
  tokenId: Text;
  lowerPriceICP: TokensICP;
  higherPriceICP: TokensICP;
  mwh: number;
  assetInfo: AssetInfoModel;
}

export interface MarketplaceSellersInfo {
  userProfile: UserProfileModel;
  tokenId: Text;
  priceICP: TokensICP;
  mwh: number;
  assetInfo: AssetInfoModel;
}