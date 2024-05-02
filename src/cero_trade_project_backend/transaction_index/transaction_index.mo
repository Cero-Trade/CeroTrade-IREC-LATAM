import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Serde "mo:serde";
import Debug "mo:base/Debug";
import List "mo:base/List";
import Buffer "mo:base/Buffer";

// canisters
import HttpService "canister:http_service";

// types
import T "../types";

shared(init_msg) actor class TransactionIndex(ENVIRONMENT_BRANCH: Text) = this {
  stable let ic : T.IC = actor ("aaaaa-aa");
  private func TransactionsCanister(cid: T.CanisterId): T.TransactionsInterface { actor (Principal.toText(cid)) };
  stable var wasm_array : [Nat] = [];

  stable let notExists = "Transaciton doesn't exists";
  stable let alreadyExists = "Transaction already exists on cero trade";


  var transactionsDirectory: HM.HashMap<T.TransactionId, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var transactionsDirectoryEntries : [(T.TransactionId, T.CanisterId)] = [];

  stable var currentCanisterid: ?T.CanisterId = null;


  /// funcs to persistent collection state
  system func preupgrade() { transactionsDirectoryEntries := Iter.toArray(transactionsDirectory.entries()) };
  system func postupgrade() {
    transactionsDirectory := HM.fromIter<T.TransactionId, T.CanisterId>(transactionsDirectoryEntries.vals(), 16, Text.equal, Text.hash);
    transactionsDirectoryEntries := [];
  };

  /// get size of transactionsDirectory collection
  public query func length(): async Nat { transactionsDirectory.size() };

  /// register wasm module to dynamic transactions canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    assert init_msg.caller == caller;

    let wasmModule = await HttpService.get("https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # ENVIRONMENT_BRANCH # "/wasm_modules/transactions.json", { headers = [] });

    let parts = Text.split(Text.replace(Text.replace(wasmModule, #char '[', ""), #char ']', ""), #char ',');
    wasm_array := Array.map<Text, Nat>(Iter.toArray(parts), func(part) {
      switch (Nat.fromText(part)) {
        case null 0;
        case (?n) n;
      }
    });
  };

  /// returns true if canister have storage memory,
  /// false if havent enough
  public func checkMemoryStatus() : async Bool {
    let status = switch(currentCanisterid) {
      case(null) throw Error.reject("Cant find transactions canisters registered");
      case(?cid) await ic.canister_status({ canister_id = cid });
    };

    status.memory_size > T.LOW_MEMORY_LIMIT
  };

  /// autonomous function, will be executed when current canister it is full
  private func createCanister(): async ?T.CanisterId {
    Debug.print(debug_show ("before registerToken: " # Nat.toText(Cycles.balance())));

    Cycles.add(300_000_000_000);
    let { canister_id } = await ic.create_canister({
      settings = ?{
        controllers = ?[Principal.fromActor(this)];
        compute_allocation = null;
        memory_allocation = null;
        freezing_threshold = null;
      }
    });

    Debug.print(debug_show ("later create_canister: " # Nat.toText(Cycles.balance())));

    try {
      let nums8 : [Nat8] = Array.map<Nat, Nat8>(wasm_array, Nat8.fromNat);

      await ic.install_code({
        arg = to_candid();
        wasm_module = Blob.fromArray(nums8);
        mode = #install;
        canister_id;
      });

      Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

      return ?canister_id
    } catch (error) {
      throw Error.reject(Error.message(error));
    }
  };

  /// register [transactionsDirectory] collection
  public func registerTransaction(txInfo: T.TransactionInfo) : async T.TransactionId {
    try {
      let errorText = "Error generating canister";

      /// get canister id and generate if need it
      let cid: T.CanisterId = switch(currentCanisterid) {
        case(null) {
          /// generate canister
          currentCanisterid := await createCanister();
          switch(currentCanisterid) {
            case(null) throw Error.reject(errorText);
            case(?cid) cid;
          };
        };
        case(?cid) {
          /// validate canister capability
          let haveMemory = await checkMemoryStatus();
          if (haveMemory) { cid } else {
            /// generate canister
            currentCanisterid := await createCanister();
            switch(currentCanisterid) {
              case(null) throw Error.reject(errorText);
              case(?cid) cid;
            };
          }
        };
      };

      // register transaction
      let txId: T.TransactionId = await TransactionsCanister(cid).registerTransaction(txInfo);

      transactionsDirectory.put(txId, cid);
      txId
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };


  public func getRedemptions(txIds: [T.TransactionId]) : async [T.TransactionInfo] {
    let txs = Buffer.Buffer<T.TransactionInfo>(100);

    Debug.print(debug_show ("before getRedemptions: " # Nat.toText(Cycles.balance())));

    for(txId in txIds.vals()) {
      switch(transactionsDirectory.get(txId)) {
        case (null) {};
        case(?cid) {
          let redemptions: [T.TransactionInfo] = await TransactionsCanister(cid).getRedemptions(txIds);
          txs.append(Buffer.fromArray<T.TransactionInfo>(redemptions));
        };
      };
    };

    Debug.print(debug_show ("later getRedemptions: " # Nat.toText(Cycles.balance())));

    Buffer.toArray<T.TransactionInfo>(txs);
  };
}
