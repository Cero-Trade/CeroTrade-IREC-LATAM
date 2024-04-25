export type TokenStatus = "redeem"|"sold"|"forSale"|"notForSale";

export interface TokenModel {
  tokenId: string;
  totalAmount: number;
  inMarket: number;
  assetInfo: AssetInfoModel;
  status: TokenStatus;
}

export type AssetType = "hydro"|"ocean"|"geothermal"|"biome"|"wind"|"sun"|"other";

export interface AssetInfoModel {
  assetType: AssetType;
  startDate: number;
  endDate: number;
  co2Emission: number;
  radioactivityEmnission: number;
  volumeProduced: number;
  deviceDetails: DeviceDetailsModel;
  specifications: SpecificationsModel;
  dates: [number];
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
