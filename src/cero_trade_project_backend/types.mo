import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Array "mo:base/Array";

// interfaces
import ICPTypes "./ICPTypes";

// types
import ENV "./env";

module {
  public let cycles: Nat = 20_000_000;
  public let cyclesCreateCanister: Nat = 100_000_000_000;

  // TODO try to change to simplest format to better filtering
  // global date format variable
  public let dateFormat: Text = "YYYY-MM-DDTHH:mm:ss.sssssssssZ";

  // amount in e8s equal to 1 ICP
  public func getE8sEquivalence(): Nat64 {
    Nat64.fromNat(switch(Nat.fromText(ENV.VITE_E8S_EQUIVALENCE)) {
      case(null) 0;
      case(?value) value;
    });
  };
  public func getCeroComission(): Nat64 {
    Nat64.fromNat(switch(Nat.fromText(ENV.VITE_CERO_COMISSION)) {
      case(null) 0;
      case(?value) value;
    });
  };

  public type UID = Principal;
  public type EvidentID = Text;
  public type CanisterId = Principal;
  public type TokenId = Text;
  public type TransactionId = Text;
  public type EvidentTransactionId = Text;
  public type RedemId = Text;
  public type CompanyLogo = [Nat8];
  public type BID = UID;
  public type TxIndex = Nat;
  public type TokenAmount = Nat;
  public type Price = { e8s: Nat64 };
  public type UserToken = Text;
  

  //
  // Users
  //
  public type RegisterForm = {
    companyId: Text;
    evidentId: EvidentID;
    companyName: Text;
    country: Text;
    city: Text;
    address: Text;
    email: Text;
  };

  public type UserInfo = {
    companyLogo: ?CompanyLogo;
    vaultToken: Text;
    principal: Principal;
    // TODO want to delete this variable and fetch data directly token canisters
    portfolio: [TokenId];
    transactions: [TransactionId];
    beneficiaries: [BID];
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
    to: ?BID;
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
    to: ?BID;
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

  //
  // Notifications types
  //
  public type NotificationId = Text;

  public type NotificationInfo = {
    id: NotificationId;
    title: Text;
    content: ?Text;
    notificationType: NotificationType;
    createdAt: Text;
    status: ?NotificationStatus;

    eventStatus: ?NotificationEventStatus;
    tokenId: ?TokenId;
    receivedBy: BID;
    triggeredBy: ?UID;
    quantity: ?TokenAmount;
  };

  public type NotificationStatus = {
    #sent: Text;
    #seen: Text;
  };

  public type NotificationEventStatus = {
    #pending: Text;
    #declined: Text;
    #accepted: Text;
  };

  public type NotificationType = {
    #general: Text;
    #redeem: Text;
    #beneficiary: Text;
  };
  
  //
  // statistic types
  //
  public type AssetStatistic = {
    mwh: TokenAmount;
    assetType: AssetType;
    redemptions: TokenAmount;
  };

  //
  // ic management types
  //
  public type WasmModuleName = {
    #token: Text;
    #users: Text;
    #transactions: Text;
    #notifications: Text;
  };

  public let LOW_MEMORY_LIMIT: Nat = 50000;

  //
  // ICP Types
  //
  public type TransferInMarketplaceArgs = {
    from: ICPTypes.Account;
    to: ICPTypes.Account;
    amount: ICPTypes.Balance;
  };

  public type PurchaseInMarketplaceArgs = {
    marketplace: ICPTypes.Account;
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
