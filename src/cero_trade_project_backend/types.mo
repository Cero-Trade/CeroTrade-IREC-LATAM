import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Array "mo:base/Array";

// Types
import IC_MANAGEMENT "./ic_management_canister_interface";
import ICRC "./ICRC";

module {
  public let ic : IC_MANAGEMENT.IC = actor ("aaaaa-aa");

  public func getControllers(canister_id: CanisterId): async ?[Principal] {
    let status = await ic.canister_status({ canister_id });
    status.settings.controllers
  };

  // global admin assert validation
  public func adminValidation(caller: Principal, controllers: ?[Principal]) {
    assert switch(controllers) {
      case(null) true;
      case(?value) Array.find<Principal>(value, func x = x == caller) != null;
    };
  };

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
  public type BlockHash = Nat64;
  public type TokenAmount = Nat;
  public type Price = ICRC.Tokens;
  
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
    ledger: ICRC.AccountIdentifier;
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
    blockHash: BlockHash;
    from: UID;
    to: Beneficiary;
    tokenId: TokenId;
    txType: TxType;
    tokenAmount: TokenAmount;
    priceICP: Price;
    date: Text;
    method: TxMethod;
  };

  public type TransactionHistoryInfo = {
    transactionId: TransactionId;
    blockHash: BlockHash;
    from: UID;
    to: Beneficiary;
    assetInfo: ?AssetInfo;
    txType: TxType;
    tokenAmount: TokenAmount;
    priceICP: Price;
    date: Text;
    method: TxMethod;
  };

  public type TxType = {
    #transfer: Text;
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
    latitude: Float;
    longitude: Float;
    address: Text;
    stateProvince: Text;
    country: Text;
  };

  public type AssetInfo = {
    tokenId: TokenId;
    assetType: AssetType;
    startDate: Text;
    endDate: Text;
    co2Emission: Float;
    radioactivityEmnission: Float;
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
    lowerPriceICP: Price;
    higherPriceICP: Price;
    assetInfo: AssetInfo;
    mwh: TokenAmount;
  };

  public type MarketplaceSellersInfo = {
    tokenId: Text;
    sellerId: UID;
    priceICP: Price;
    assetInfo: ?AssetInfo;
    mwh: TokenAmount;
  };

  public type TokenMarketInfo = {
    totalQuantity: TokenAmount;
    usersxToken: HM.HashMap<UID, UserTokenInfo>;
  };

  public type UserTokenInfo = {
    quantity: TokenAmount;
    priceICP: Price;
  };

  public type CanisterSettings = IC_MANAGEMENT.CanisterSettings;

  public type WasmModule = IC_MANAGEMENT.WasmModule;

  public type WasmModuleName = {
    #token: Text;
    #users: Text;
    #transactions: Text;
  };

  public let LOW_MEMORY_LIMIT: Nat = 50000;

  public type UsersInterface = actor {
    length: query () -> async Nat;
    registerUser: (uid: UID, token: Text) -> async();
    deleteUser: (uid: UID) -> async();
    storeCompanyLogo: (uid: UID, avatar: CompanyLogo) -> async();
    getCompanyLogo: query (uid: UID) -> async CompanyLogo;
    updatePorfolio: (uid: UID, tokenId: TokenId) -> async();
    deletePorfolio: (uid: UID, tokenId: TokenId) -> async();
    updateTransactions: (uid: UID, tx: TransactionId) -> async();
    getPortfolioTokenIds: query (uid: UID) -> async [TokenId];
    getTransactionIds: query (uid: UID) -> async [TransactionId];
    getBeneficiaries: query (uid: UID) -> async [Beneficiary];
    getUserToken: query (uid: UID) -> async Text;
    validateToken: query (uid: UID, token: Text) -> async Bool;
    getLedger: query (uid: UID) -> async Blob;
  };

  public type TokenInterface = actor {
    init: (assetMetadata: AssetInfo) -> async();
    mintToken: (uid: UID, amount: TokenAmount, inMarket: TokenAmount) -> async ();
    burnToken: (uid: UID, amount: TokenAmount, inMarket: TokenAmount) -> async ();
    getUserMinted: query (uid: UID) -> async TokenInfo;
    getAssetInfo: query () -> async AssetInfo;
    getRemainingAmount: query () -> async TokenAmount;
    getTokenId: query () -> async TokenId;
    getCanisterId: query () -> async CanisterId;
    purchaseToken: (uid: UID, recipent: UID, amount: TokenAmount, inMarket: TokenAmount) -> async();
  };

  public type TransactionsInterface = actor {
    length: query () -> async Nat;
    registerTransaction: (tx: TransactionInfo) -> async TransactionId;
    getTransactionsById: query (txIds: [TransactionId], txType: ?TxType, priceRange: ?[Price], mwhRange: ?[TokenAmount], method: ?TxMethod, rangeDates: ?[Text]) -> async [TransactionInfo];
  };
}
