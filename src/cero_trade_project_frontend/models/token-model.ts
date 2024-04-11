export interface TokenModel {
  tokenId: string;
  totalAmount: number;
  inMarket: number;
  assetInfo: AssetInfoModel
}

export interface AssetInfoModel {
  assetType: AssetType; // AssetType
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
  group: AssetType; // AssetType
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

export type AssetType = "hydroenergy"|"wind"|"solar"|"other";