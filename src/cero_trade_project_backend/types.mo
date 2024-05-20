import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Array "mo:base/Array";

// types
import ICPTypes "./ICPTypes";

module {
  // TODO try to change to simplest format to better filtering
  // global date format variable
  public let dateFormat: Text = "YYYY-MM-DDTHH:mm:ss.sssssssssZ";

  public type UID = Principal;
  public type CanisterId = Principal;
  public type TokenId = Text;
  public type TransactionId = Text;
  public type RedemId = Text;
  public type CompanyLogo = [Nat8];
  public type Beneficiary = UID;
  public type TxIndex = Nat;
  public type TokenAmount = Nat;
  public type Price = { e8s: Nat64 };
  public type AccountIdentifier = Blob.Blob;
  
  //
  // UsersAgent
  //
  public type RegisterForm = {
    companyId: Text;
    companyName: Text;
    country: Text;
    city: Text;
    address: Text;
    email: Text;
  };

  //
  // Users
  //
  public type UserInfo = {
    companyLogo: ?CompanyLogo;
    vaultToken: Text;
    principal: Principal;
    ledger: AccountIdentifier;
    portfolio: [TokenId];
    transactions: [TransactionId];
    beneficiaries: [Beneficiary];
  };

  public type UserProfile = {
    companyLogo: CompanyLogo;
    principalId: Text;
    companyId: Text;
    companyName: Text;
    city: Text;
    country: Text;
    address: Text;
    email: Text;
    createdAt: Text;
    updatedAt: Text;
  };

  public type TokenInfo = {
    tokenId: TokenId;
    totalAmount: TokenAmount;
    inMarket: TokenAmount;
    assetInfo: AssetInfo;
  };

  public type TxMethod = {
    #blockchainTransfer: Text;
    #bankTransfer: Text;
  };

  public type TransactionInfo = {
    transactionId: TransactionId;
    txIndex: TxIndex;
    from: UID;
    to: ?Beneficiary;
    tokenId: TokenId;
    txType: TxType;
    tokenAmount: TokenAmount;
    priceE8S: ?Price;
    date: Text;
    method: TxMethod;
  };

  public type TransactionHistoryInfo = {
    transactionId: TransactionId;
    txIndex: TxIndex;
    from: UID;
    to: ?Beneficiary;
    assetInfo: ?AssetInfo;
    txType: TxType;
    tokenAmount: TokenAmount;
    priceE8S: ?Price;
    date: Text;
    method: TxMethod;
  };

  public type TxType = {
    #purchase: Text;
    #putOnSale: Text;
    #takeOffMarketplace: Text;
    #redemption: Text;
  };

  //
  // Token
  //
  public type AssetType = {
    #hydro: Text;
    #ocean: Text;
    #geothermal: Text;
    #biome: Text;
    #wind: Text;
    #sun: Text;
    #other: Text;
  };

  public type DeviceDetails = {
    name: Text;
    deviceType: Text;
    group: AssetType;
    description: Text;
  };

  public type Specifications = {
    deviceCode: Text;
    capacity: TokenAmount;
    location: Text;
    latitude: Text;
    longitude: Text;
    address: Text;
    stateProvince: Text;
    country: Text;
  };

  public type AssetInfo = {
    tokenId: TokenId;
    assetType: AssetType;
    startDate: Text;
    endDate: Text;
    co2Emission: Text;
    radioactivityEmnission: Text;
    volumeProduced: TokenAmount;
    deviceDetails: DeviceDetails;
    specifications: Specifications;
    dates: [Text];
  };

  //
  // Market types
  //

  public type MarketplaceInfo = {
    tokenId: Text;
    lowerPriceE8S: Price;
    higherPriceE8S: Price;
    assetInfo: AssetInfo;
    mwh: TokenAmount;
  };

  public type MarketplaceSellersInfo = {
    tokenId: Text;
    sellerId: UID;
    priceE8S: Price;
    assetInfo: ?AssetInfo;
    mwh: TokenAmount;
  };

  public type TokenMarketInfo = {
    totalQuantity: TokenAmount;
    usersxToken: HM.HashMap<UID, UserTokenInfo>;
  };

  public type UserTokenInfo = {
    quantity: TokenAmount;
    priceE8S: Price;
  };

  public type WasmModuleName = {
    #token: Text;
    #users: Text;
    #transactions: Text;
  };

  public let LOW_MEMORY_LIMIT: Nat = 50000;

  public type MintToUserArgs = {
    funder: UID;
    to: ICPTypes.Account;
    amount: ICPTypes.Balance;
  };

  public type SellInMarketplaceArgs = {
    seller: Principal;
    seller_subaccount: ?ICPTypes.Subaccount;
    marketplace: ICPTypes.Account;
    amount: ICPTypes.Balance;
  };

  public type PurchaseInMarketplaceArgs = {
    marketplace: CanisterId;
    seller: ICPTypes.Account;
    buyer: ICPTypes.Account;
    amount: ICPTypes.Balance;
    priceE8S: Price;
  };

  public type RedeemArgs = {
    owner: ICPTypes.Account;
    amount: ICPTypes.Balance;
  };
}
