export type TokenStatus = "redeem"|"sold"|"forSale"|"notForSale";

export interface TokenModel {
  tokenId: string;
  totalAmount: number;
  inMarket: number;
  assetInfo: AssetInfoModel;
}

export type AssetType = "Solar"|"Wind"|"Hydro-Electric"|"Thermal"|"Other";

export interface AssetInfoModel {
  tokenId: string;
  startDate: Date;
  endDate: Date;
  co2Emission: number;
  radioactivityEmission: number;
  volumeProduced: number;
  deviceDetails: DeviceDetailsModel;
  specifications: SpecificationsModel;
};

export interface DeviceDetailsModel {
  name: string;
  deviceType: AssetType;
  description: string;
};

export interface SpecificationsModel {
  deviceCode: string;
  location: string;
  latitude: number;
  longitude: number;
  country: string;
};
