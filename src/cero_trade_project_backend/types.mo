import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";

// Types
import ICRC "./ICRC";

module {
  public type UID = Principal;
  public type CanisterId = Principal;
  public type TokenId = Text;
  public type TransactionId = Text;
  public type RedemId = Text;
  public type CompanyLogo = [Nat8];
  public type Beneficiary = Text;
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
    profile: Text;
  };

  public type TokenInfo = {
    tokenId: TokenId;
    totalAmount: TokenAmount;
    inMarket: TokenAmount;
    assetInfo: AssetInfo;
  };
  
  // public type RedemInfo = {
  //   redemId: RedemId;
  //   tokenId: TokenId;
  //   redAmount: Nat;
  //   tokenInfo: TokenInfo;
  //   redemStatement: ?Blob;
  //   date: Nat64;
  // };

  public type TransactionRecipent = {
    #redemptionRecipent: Beneficiary;
    #transferRecipent: UID;
  };

  public type TransactionInfo = {
    transactionId: TransactionId;
    blockHash: BlockHash;
    from: UID;
    to: TransactionRecipent;
    tokenId: TokenId;
    txType: TxType;
    tokenAmount: TokenAmount;
    priceICP: Price;
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
    startDate: Nat64;
    endDate: Nat64;
    co2Emission: Float;
    radioactivityEmnission: Float;
    volumeProduced: TokenAmount;
    deviceDetails: DeviceDetails;
    specifications: Specifications;
    dates: [Nat64];
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

  public type TokenMarketInfo = {
    totalQuantity: TokenAmount;
    usersxToken: HM.HashMap<UID, UserTokenInfo>;
  };

  public type UserTokenInfo = {
    quantity: TokenAmount;
    priceICP: Price;
  };


  public type CanisterSettings = {
    controllers: ?[Principal];
    compute_allocation: ?Nat;
    memory_allocation: ?Nat;
    freezing_threshold: ?Nat;
  };

  public type WasmModule = Blob;

  public type WasmModuleName = {
    #users: Text;
    #transactions: Text;
    #token: Text;
  };

  public let LOW_MEMORY_LIMIT: Nat = 50000;

  //3. Declaring the management canister which you use to make the Canister dictionary
  public type IC = actor {
    create_canister: shared {settings: ?CanisterSettings} -> async {canister_id: CanisterId};
    update_settings : shared {
      canister_id: Principal;
      settings: CanisterSettings;
    } -> async();
    canister_status: shared {canister_id: CanisterId} -> async {
      status: { #stopped; #stopping; #running };
      memory_size: Nat;
      cycles: Nat;
      settings: CanisterSettings;
      idle_cycles_burned_per_day: Nat;
      module_hash: ?[Nat8];
    };
    install_code : shared {
      arg: Blob;
      wasm_module: WasmModule;
      mode: { #reinstall; #upgrade; #install };
      canister_id: CanisterId;
    } -> async();
    uninstall_code : shared {canister_id: CanisterId} -> async();
    deposit_cycles: shared {canister_id: CanisterId} -> async();
    start_canister: shared {canister_id: CanisterId} -> async();
    stop_canister: shared {canister_id: CanisterId} -> async();
    delete_canister: shared {canister_id: CanisterId} -> async();
  };

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
    getRedemptions: query (txIds: [TransactionId]) -> async [TransactionInfo];
  };
}
