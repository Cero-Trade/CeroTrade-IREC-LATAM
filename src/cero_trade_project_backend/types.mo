import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import ICRC1 "mo:icrc1-mo/ICRC1";

// interfaces
import ICPTypes "./ICPTypes";

// types
import ENV "./env";

module {
  public let cycles: Nat = 20_000_000;
  public let cyclesHttpOutcall: Nat = 20_860_000_000;
  public let cyclesCreateCanister: Nat = 300_000_000_000;

  public let tokenDecimals: Nat8 = 8;

  public func githubBranch(): Text {
    switch(ENV.DFX_NETWORK) {
      case("ic") "main";
      case _ "develop";
    };
  };

  // TODO try to change to simplest format to better filtering
  // global date format variable
  public let dateFormat: Text = "YYYY-MM-DDTHH:mm:ss.sssssssssZ";

  public func getCeroComission(): Nat64 {
    Nat64.fromNat(switch(Nat.fromText(ENV.VITE_CERO_COMISSION)) {
      case(null) 0;
      case(?value) value;
    });
  };
  
  /// helper function to convert Text to Float
  public func textToFloat(t: Text): async Float {
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

    f
  };

  /// helper function to convert Text to Nat
  public func textToNat(t: Text): async Nat {
    let f = await textToFloat(t);
    let rounded = f + 0.5;
    Int.abs(Float.toInt(rounded));
  };

  /// helper function to convert Text to Token Balance
  public func textToToken(t: Text, decimals: ?Nat8): async ICPTypes.Balance {
    let f = await textToFloat(t);
    
    let decimalsValue : Float = Float.fromInt64(Int64.fromNat64(Nat64.fromNat(Nat8.toNat(switch(decimals) {
      case(null) tokenDecimals;
      case(?value) value;
    }))));

    let float = f * Float.pow(10.0, decimalsValue);
    Int.abs(Float.toInt(float))
  };

  /// helper function to convert Token Balance to Text
  public func tokenToText(token: ICPTypes.Balance, decimals: ?Nat8): async Text {
    let f = await textToFloat(Nat.toText(token));
    
    let decimalsValue : Float = Float.fromInt64(Int64.fromNat64(Nat64.fromNat(Nat8.toNat(switch(decimals) {
      case(null) tokenDecimals;
      case(?value) value;
    }))));

    let float = f / Float.pow(10.0, decimalsValue);
    Float.toText(float)
  };

  public type UID = Principal;
  public type EvidentID = Text;
  public type EvidentBID = Text;
  public type CanisterId = Principal;
  public type TokenId = Text;
  public type TransactionId = Text;
  public type EvidentTransactionId = Text;
  public type RedemId = Text;
  public type ArrayFile = [Nat8];
  public type BID = UID;
  public type TxIndex = Nat;
  public type TxHash = Text;
  public type TokenAmount = Nat;
  public type Price = { e8s: Nat64 };
  public type UserTokenAuth = Text;

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
    companyId: Text;
    companyName: Text;
    country: Text;
    city: Text;
    address: Text;
    email: Text;
    vaultToken: UserTokenAuth;
    evidentBID: EvidentBID;
    principal: Principal;
  };

  public type UserProfile = {
    companyLogo: ArrayFile;
    principalId: Principal;
    evidentBID: EvidentBID;
    companyId: Text;
    companyName: Text;
    city: Text;
    country: Text;
    address: Text;
    email: Text;
  };

  public type SinglePortfolio = {
    tokenInfo: TokenInfo;
    redemptions: [TransactionInfo];
  };

  public type Portfolio = {
    tokenInfo: TokenInfo;
    redemptions: [TokenAmount];
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
    ledgerTxHash: ?TxHash;
    comissionTxHash: ?TxHash;
    from: { principal: UID; name: Text };
    to: ?{ principal: BID; name: Text };
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
    ledgerTxHash: ?TxHash;
    comissionTxHash: ?TxHash;
    from: { principal: UID; name: Text };
    to: ?{ principal: BID; name: Text };
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
    #burn: Text;
    #mint: Text;
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
    location: Text;
    latitude: Text;
    longitude: Text;
    country: Text;
  };

  public type AssetInfo = {
    tokenId: TokenId;
    startDate: Text;
    endDate: Text;
    co2Emission: Text;
    radioactivityEmission: Text;
    volumeProduced: TokenAmount;
    deviceDetails: DeviceDetails;
    specifications: Specifications;
  };

  public type RedemptionItem = {
    id: TokenId;
    volume: TokenAmount;
  };

  public type RedemptionRequest = {
    id: TokenId;
    txIndex: TxIndex;
  };

  public type RedemptionItemPdf = {
    id: TokenId;
    txIndex: TxIndex;
    comissionBlock: TxIndex;
    volume: TokenAmount;
    pdf: ArrayFile;
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
    tokenId: TokenId;
    sellerId: UID;
    sellerName: Text;
    priceE8S: Price;
    mwh: TokenAmount;
  };

  public type MarketplaceSellersResponse = {
    tokenId: TokenId;
    sellerId: UID;
    sellerName: Text;
    priceE8S: Price;
    assetInfo: ?AssetInfo;
    mwh: TokenAmount;
  };

  public type TokenMarketInfo = {
    totalQuantity: TokenAmount;
    usersxToken: HM.HashMap<UID, UserTokenInfo>;
  };

  public type UserTokenInfo = {
    sellerName: Text;
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
    receivedBy: BID;
    triggeredBy: ?UID;

    items: ?[RedemptionItem];
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
  public type AssetStatisticPriceTrend = {
    seller: UID;
    priceE8S: Price;
  };

  public type AssetStatistic = {
    mwh: TokenAmount;
    assetType: AssetType;
    redemptions: TokenAmount;
    sells: TokenAmount;
    priceTrend: ?AssetStatisticPriceTrend;
  };

  public type AssetStatisticResponse = {
    mwh: TokenAmount;
    assetType: AssetType;
    redemptions: TokenAmount;
    sells: TokenAmount;
    priceE8STrend: Price;
  };

  //
  // bucket types
  //
  public type BucketId = Text;

  //
  // ICP Types
  //
  public type PurchaseTxResponse = {
    comission_block: TxIndex;
    ledger_block: TxIndex;
    token_result: (ICRC1.TransferResult, AssetInfo);
  };

  public type TokenTxResponse = {
    comission_block: TxIndex;
    token_result: ICRC1.TransferResult;
  };

  public type PurchaseTxIndexResponse = {
    comission_block: TxIndex;
    ledger_block: TxIndex;
    token_block: (TxIndex, AssetInfo);
  };

  public type TokenTxIndexResponse = {
    comission_block: TxIndex;
    token_block: TxIndex;
  };

  public type MintTxIndexResponse = {
    comission_block: TxIndex;
    token_block: (TxIndex, AssetInfo);
  };

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
