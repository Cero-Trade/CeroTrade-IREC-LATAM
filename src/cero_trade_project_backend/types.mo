import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";

module {
  public type UID = Principal;
  public type CanisterId = Principal;
  public type TokenId = Text;
  public type TransactionId = Nat;
  public type RedemId = Nat;
  public type ComanyLogo = Blob;


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
    companyLogo: ?ComanyLogo;
    vaultToken: Text;
    principal: Principal;
    ledger: Blob;
    portfolio: HM.HashMap<TokenId, TokenInfo>;
    redemptions: TM.TrieMap<RedemId, RedemInfo>;
    transactions: TM.TrieMap<TransactionId, TransactionInfo>;
  };

  public type UserProfile = {
    companyLogo: [Nat8];
  };

  public type TokenInfo = {
    tokenId: TokenId;
    totalAmount: Nat;
    inMarket: Nat;
    assetInfo: AssetInfo
  };
  
  public type RedemInfo = {
    redemId: RedemId;
    tokenId: TokenId;
    redAmount: Nat;
    tokenInfo: TokenInfo;
    redemStatement: ?Blob;
    date: Nat64;
  };

  public type TransactionInfo = {
    transactionId: TransactionId;
    tokenId: TokenId;
    txType: Text;
    source: Text;
    country: Text;
    mwh: Text;
    assetId: Text;
    date: Nat64;
  };

  //
  // Token
  //
  public type AssetType = {
    #hydroenergy: Text;
    #wind: Text;
    #solar: Text;
    #other: Text;
  };

  public type DeviceDetails = {
    name: Text;
    deviceType: Text;
    group: Text; // AssetType
    description: Text;
  };

  public type Specifications = {
    deviceCode: Text;
    capacity: Float;
    location: Text;
    latitude: Float;
    longitude: Float;
    address: Text;
    stateProvince: Text;
    country: Text;
  };

  public type AssetInfo = {
    assetType: Text; // AssetType
    startDate: Nat64;
    endDate: Nat64;
    co2Emission: Float;
    radioactivityEmnission: Float;
    volumeProduced: Nat;
    deviceDetails: DeviceDetails;
    specifications: Specifications;
    // TODO checkout usage of this date format
    dates: [Nat64];
  };
}
