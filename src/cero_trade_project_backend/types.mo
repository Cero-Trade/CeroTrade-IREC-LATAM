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



  public type CanisterSettings = {
    controllers: ?[Principal];
    compute_allocation: ?Nat;
    memory_allocation: ?Nat;
    freezing_threshold: ?Nat;
  };

  public type WasmModule = Blob;

  //3. Declaring the management canister which you use to make the Canister dictionary
  public type IC = actor {
    create_canister: shared {settings: ?CanisterSettings} -> async {canister_id: CanisterId};
    update_settings : shared {
      canister_id: Principal;
      settings: CanisterSettings;
    } -> async ();
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
    } -> async ();
    uninstall_code : shared {canister_id: CanisterId} -> async ();
    deposit_cycles: shared {canister_id: CanisterId} -> async ();
    start_canister: shared {canister_id: CanisterId} -> async ();
    stop_canister: shared {canister_id: CanisterId} -> async ();
    delete_canister: shared {canister_id: CanisterId} -> async ();
  };

  public type UsersInterface = actor {
    length: () -> async Nat;
    registerUser: (uid: UID, token: Text) -> async CanisterId;
    deleteUser: (uid: UID) -> async ();
    storeCompanyLogo: (uid: UID, avatar: Blob) -> async ();
    getCompanyLogo: (uid: UID) -> async Blob;
    updatePorfolio: (uid: UID, token: TokenInfo) -> async ();
    updateRedemptions: (uid: UID, redem: RedemInfo) -> async ();
    updateTransactions: (uid: UID, tx: TransactionInfo) -> async ();
    getPortfolio: (uid: UID) -> async [TokenInfo];
    getRedemptions: (uid: UID) -> async [RedemInfo];
    getTransactions: (uid: UID) -> async [TransactionInfo];
    getUserToken: (uid: UID) -> async Text;
    validateToken: (uid: UID, token: Text) -> async Bool;
  };

  public type TokenInterface = actor {
    init: (assetMetadata: AssetInfo) -> async ();
    mintToken: (UID, Nat) -> async TokenInfo;
    burnToken: (UID, Nat) -> async TokenInfo;
    getUserMinted: query (UID) -> async Nat;
    getAssetInfo: query () -> async AssetInfo;
    getRemainingAmount: query () -> async Nat;
    getTokenId: query () -> async TokenId;
    getCanisterId: query () -> async Principal;
  };
}
