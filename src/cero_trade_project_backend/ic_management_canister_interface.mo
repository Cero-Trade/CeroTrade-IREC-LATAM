import HM = "mo:base/HashMap";
import TM "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Array "mo:base/Array";

module IC_MANAGEMENT_CANISTER_INTERFACE {
  public type CanisterSettings = {
    controllers: ?[Principal];
    compute_allocation: ?Nat;
    memory_allocation: ?Nat;
    freezing_threshold: ?Nat;
  };

  public type WasmModule = Blob;

  public type Satoshi = Nat64;
  public type MilisatoshiPerBytes = Nat64;

  public type Outpoint = {
    txid: Blob;
    vout: Nat32;
  };

  public type UTXO = {
    outpoint: Outpoint;
    value: Satoshi;
    height: Nat32;
  };

  public type BlockHash = Blob;

  public type EcdsaCurve = {
    #secp256k1: Nat32;
  };

  public type BitcoinAddress = Text;

  public type BitcoinNetwork = {
    #mainnet: Text;
    #testnet: Text;
  };

  //3. Declaring the management canister which you use to make the Canister dictionary
  public type IC = actor {
    create_canister: shared {settings: ?CanisterSettings} -> async {canister_id: Principal};
    update_settings: shared {
      canister_id: Principal;
      settings: CanisterSettings;
    } -> async();
    canister_status: shared {canister_id: Principal} -> async {
      status: { #stopped; #stopping; #running };
      memory_size: Nat;
      cycles: Nat;
      settings: CanisterSettings;
      idle_cycles_burned_per_day: Nat;
      module_hash: ?[Nat8];
    };
    install_code: shared {
      arg: Blob;
      wasm_module: WasmModule;
      mode: { #reinstall; #upgrade; #install };
      canister_id: Principal;
    } -> async();
    uninstall_code: shared {canister_id: Principal} -> async();
    deposit_cycles: shared {canister_id: Principal} -> async();
    start_canister: shared {canister_id: Principal} -> async();
    stop_canister: shared {canister_id: Principal} -> async();
    delete_canister: shared {canister_id: Principal} -> async();
    raw_rand: () -> async Blob;

    // Threshold ECDSA signature
    ecdsa_public_key: {
      canister_id: ?Principal; derivation_path: [Blob];
      key_id: { curve: EcdsaCurve; name: Text };
    } -> async { public_key: Blob; chain_code: Blob; };
    sign_with_ecdsa: {
      message_hash: Blob; derivation_path: [Blob];
      key_id: { curve: EcdsaCurve; name: Text };
    } -> async { signature: Blob; };

    // Bitcoin interface
    bitcoin_get_balance: { address: BitcoinAddress; network: BitcoinNetwork; min_confirmations: ?Nat32; } -> async Satoshi;
    bitcoin_get_balance_query: query { address: BitcoinAddress; network: BitcoinNetwork; min_confirmations: ?Nat32; } -> async Satoshi; /*not-found*/
    bitcoin_get_utxos: {
      address: BitcoinAddress; network: BitcoinNetwork;
      filter: ?{ #min_confirmations: Nat32; #page: Blob; };
    } -> async { utxos: [UTXO]; tip_block_hash: BlockHash; tip_height: Nat32; next_page: ?Blob; };
    bitcoin_get_utxos_query: query {
      address: BitcoinAddress; network: BitcoinNetwork;
      filter: ?{ min_confirmations: Nat32; page: Blob; };
    } -> async { utxos: [UTXO]; tip_block_hash: BlockHash; tip_height: Nat32; next_page: ?Blob; }; /*not-found*/
    bitcoin_send_transaction: { transaction: Blob; network: BitcoinNetwork; } -> async();
    bitcoin_get_current_fee_percentiles: { network: BitcoinNetwork; } -> async [MilisatoshiPerBytes];
  };
}