import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Array "mo:base/Array";

// interfaces
import ICPTypes "./ICPTypes";

// types
import ENV "./env";

module {
  public let cycles: Nat = 20_000_000;
  public let cyclesHttpOutcall: Nat = 20_850_346_400;
  public let cyclesCreateCanister: Nat = 300_000_000_000;

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

  /// helper function to convert Text to Nat
  public func textToNat(t: Text): async Nat {
    var i : Float = 1;
    var f : Float = 0;
    var isDecimal : Bool = false;

    for (c in t.chars()) {
      if (Char.isDigit(c)) {
        let charToNat : Nat64 = Nat64.fromNat(Nat32.toNat(Char.toNat32(c) -48));
        let natToFloat : Float = Float.fromInt64(Int64.fromNat64(charToNat));
        if (isDecimal) {
          let n : Float = natToFloat / Float.pow(10, i);
          f := f + n;
        } else {
          f := f * 10 + natToFloat;
        };
        i := i + 1;
      } else {
        if (Char.equal(c, '.') or Char.equal(c, ',')) {
          f := f / Float.pow(10, i); // Force decimal
          f := f * Float.pow(10, i); // Correction
          isDecimal := true;
          i := 1;
        } else {
          throw Error.reject("NaN");
        };
      };
    };

    Int.abs(Float.toInt(f));
  };

  public type UID = Principal;
  public type EvidentID = Text;
  public type CanisterId = Principal;
  public type TokenId = Text;
  public type TransactionId = Text;
  public type EvidentTransactionId = Text;
  public type RedemId = Text;
  public type ArrayFile = [Nat8];
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

  public type UpdateUserForm = {
    companyId: Text;
    companyName: Text;
    country: Text;
    city: Text;
    address: Text;
    email: Text;
  };

  public type UserInfo = {
    companyLogo: ?ArrayFile;
    vaultToken: Text;
    principal: Principal;
  };

  public type UserProfile = {
    companyLogo: ArrayFile;
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
    redemptionPdf: ?ArrayFile;
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
    redemptionPdf: ?ArrayFile;
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
    #Solar: Text;
    #Wind: Text;
    #HydroElectric: Text;
    #Thermal: Text;
    #Other: Text;
  };

  public type DeviceDetails = {
    name: Text;
    deviceType: AssetType;
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

    redeemPeriodStart: ?Text;
    redeemPeriodEnd: ?Text;
    redeemLocale: ?Text;
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
  // bucket types
  //
  public type BucketId = Text;

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
