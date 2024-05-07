export type TokenStatus = "redeem"|"sold"|"forSale"|"notForSale";

export interface TokenModel {
  tokenId: string;
  totalAmount: number;
  inMarket: number;
  assetInfo: AssetInfoModel;
}

export type AssetType = "hydro"|"ocean"|"geothermal"|"biome"|"wind"|"sun"|"other";

export interface AssetInfoModel {
  assetType: AssetType;
  startDate: Date;
  endDate: Date;
  co2Emission: number;
  radioactivityEmnission: number;
  volumeProduced: number;
  deviceDetails: DeviceDetailsModel;
  specifications: SpecificationsModel;
  dates: Date[];
};

export interface DeviceDetailsModel {
  name: string;
  deviceType: string;
  group: AssetType;
  description: string;
};

export interface SpecificationsModel {
  deviceCode: string;
  capacity: number;
  location: string;
  latitude: number;
  longitude: number;
  address: string;
  stateProvince: string;
  country: string;
};
