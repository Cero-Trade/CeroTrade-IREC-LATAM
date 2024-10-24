import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Serde "mo:serde";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

// interfaces
import IC_MANAGEMENT "../ic_management_canister_interface";
import Transactions "../transactions/transactions_interface";
import HTTP "../http_service/http_service_interface";

// types
import T "../types";
import ENV "../env";

actor class TransactionIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;


  var transactionsDirectory: HM.HashMap<T.TransactionId, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var transactionsDirectoryEntries : [(T.TransactionId, T.CanisterId)] = [];

  stable var currentCanisterid: ?T.CanisterId = null;


  /// funcs to persistent collection state
  system func preupgrade() { transactionsDirectoryEntries := Iter.toArray(transactionsDirectory.entries()) };
  system func postupgrade() {
    transactionsDirectory := HM.fromIter<T.TransactionId, T.CanisterId>(transactionsDirectoryEntries.vals(), 16, Text.equal, Text.hash);
    transactionsDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };

  /// get size of transactionsDirectory collection
  public query func length(): async Nat { transactionsDirectory.size() };

  /// get canister controllers
  public shared({ caller }) func getControllers(): async ?[Principal] {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    (await IC_MANAGEMENT.ic.canister_status({ canister_id = Principal.fromActor(this) })).settings.controllers;
  };

  /// register canister controllers
  public shared({ caller }) func registerControllers(): async () {
    _callValidation(caller);

    controllers := (await IC_MANAGEMENT.ic.canister_status({ canister_id = Principal.fromActor(this) })).settings.controllers;
  };

  /// register wasm module to dynamic transactions canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    _callValidation(caller);

    try {
      let wasmModule = await HTTP.canister.get({
        url = HTTP.apiUrl # "dev/wasm-modules/transactions?githubBranch=" # T.githubBranch();
        port = null;
        uid = null;
        headers = []
      });

      let parts = Text.split(Text.replace(Text.replace(wasmModule, #char '[', ""), #char ']', ""), #char ',');
      let wasm_array = Array.map<Text, Nat>(Iter.toArray(parts), func(part) {
        switch (Nat.fromText(part)) {
          case null 0;
          case (?n) n;
        }
      });
      let nums8 : [Nat8] = Array.map<Nat, Nat8>(wasm_array, Nat8.fromNat);

      // register wasm
      wasm_module := Blob.fromArray(nums8);

      // update deployed canisters
      let deployedCanisters = Buffer.Buffer<T.CanisterId>(50);
      for (cid in transactionsDirectory.vals()) {
        if (not(Buffer.contains<T.CanisterId>(deployedCanisters, cid, Principal.equal))) {
          deployedCanisters.append(Buffer.fromArray<T.CanisterId>([cid]));
        };
      };

      if (deployedCanisters.size() == 0) {
        switch(currentCanisterid) {
          case(null) {};
          case(?cid) deployedCanisters.add(cid);
        };
      };

      for (canister_id in deployedCanisters.vals()) {
        await IC_MANAGEMENT.ic.install_code({
          arg = to_candid();
          wasm_module;
          mode = #upgrade;
          canister_id;
        });
      };
    } catch (error) {
      Debug.print("⭕ Error fetching WASM module: " # Error.message(error));
      throw error;
    }
  };

  /// resume all deployed canisters.
  ///
  /// only resume one if provide canister id
  public shared({ caller }) func startAllDeployedCanisters<system>(cid: ?T.CanisterId): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(cid) {
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.start_canister({ canister_id });
      };
      case(null) {
        let deployedCanisters = Buffer.Buffer<T.CanisterId>(50);
        for (canister_id in transactionsDirectory.vals()) {
          if (not(Buffer.contains<T.CanisterId>(deployedCanisters, canister_id, Principal.equal))) {
            Cycles.add<system>(T.cycles);
            await IC_MANAGEMENT.ic.start_canister({ canister_id });
            deployedCanisters.add(canister_id);
          };
        };
      };
    };
  };

  /// stop all deployed canisters.
  ///
  /// only stop one if provide canister id
  public shared({ caller }) func stopAllDeployedCanisters<system>(cid: ?T.CanisterId): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(cid) {
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
      };
      case(null) {
        let deployedCanisters = Buffer.Buffer<T.CanisterId>(50);
        for (cid in transactionsDirectory.vals()) {
          if (not(Buffer.contains<T.CanisterId>(deployedCanisters, cid, Principal.equal))) {
            deployedCanisters.append(Buffer.fromArray<T.CanisterId>([cid]));
          };
        };

        for(canister_id in deployedCanisters.vals()) {
          Cycles.add<system>(T.cycles);
          await IC_MANAGEMENT.ic.stop_canister({ canister_id });
        };
      };
    };
  };

  /// stop all deployed canisters and delete
  ///
  /// only delete one if provide canister id
  public shared({ caller }) func deleteDeployedCanister<system>(cid: ?T.CanisterId): async () {
    _callValidation(caller);

    switch(cid) {
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
        await IC_MANAGEMENT.ic.delete_canister({ canister_id });

        for((txId, cid) in transactionsDirectory.entries()) {
          if (cid == canister_id) return transactionsDirectory.delete(txId);
        };
      };
      case(null) {
        let deletedCanisters = Buffer.Buffer<T.CanisterId>(16);

        for((txId, canister_id) in transactionsDirectory.entries()) {
          let canisterIsDeleted = Buffer.contains<T.CanisterId>(deletedCanisters, canister_id, Principal.equal);
          if (not canisterIsDeleted) {
            Cycles.add<system>(T.cycles);
            await IC_MANAGEMENT.ic.stop_canister({ canister_id });
            await IC_MANAGEMENT.ic.delete_canister({ canister_id });
            deletedCanisters.add(canister_id);
          };

          let _ = transactionsDirectory.remove(txId);
        };
      };
    };
  };

  /// returns true if canister have storage memory,
  /// false if havent enough
  public func checkMemoryStatus() : async Bool {
    let status = switch(currentCanisterid) {
      case(null) throw Error.reject("Cant find transactions canisters registered");
      case(?cid) await IC_MANAGEMENT.ic.canister_status({ canister_id = cid });
    };

    status.memory_size > IC_MANAGEMENT.LOW_MEMORY_LIMIT
  };

  /// autonomous function, will be executed when current canister it is full
  private func _createCanister<system>(): async ?T.CanisterId {
    Debug.print(debug_show ("before registerToken: " # Nat.toText(Cycles.balance())));

    Cycles.add<system>(T.cyclesCreateCanister);
    let { canister_id } = await IC_MANAGEMENT.ic.create_canister({
      settings = ?{
        controllers = switch(controllers) {
          case(null) null;
          case(?value) {
            let currentControllers = Buffer.fromArray<Principal>(value);
            currentControllers.add(Principal.fromActor(this));
            ?Buffer.toArray<Principal>(currentControllers);
          };
        };
        compute_allocation = null;
        memory_allocation = null;
        freezing_threshold = null;
      }
    });

    Debug.print(debug_show ("later create_canister: " # Nat.toText(Cycles.balance())));

    try {
      await IC_MANAGEMENT.ic.install_code({
        arg = to_candid();
        wasm_module;
        mode = #install;
        canister_id;
      });

      Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

      return ?canister_id
    } catch (error) {
      throw Error.reject(Error.message(error));
    }
  };

  // ======================================================================================================== //

  /// register [transactionsDirectory] collection
  public shared({ caller }) func registerTransaction(txInfo: T.TransactionInfo) : async T.TransactionId {
    _callValidation(caller);

    try {
      let errorText = "Error generating canister";

      // TODO review this flow part <--
      let txHashes = switch(ENV.DFX_NETWORK) {
        case("ic") "unknown"/* await HTTP.canister.post({
          url = HTTP.apiUrl # "rosetta/";
          port = null;
          uid = null;
          headers = [];
          bodyJson = switch(Serde.JSON.toText(to_candid({
            blocks = [txInfo.comissionTxHash, txInfo.ledgerTxHash];
          }), ["blocks"], null)) {
            case(#err(error)) throw Error.reject("Cannot serialize data");
            case(#ok(value)) value;
          };
        }) */;
        case(_) "unknown";
      };
      Debug.print("txBlock ⭐ ----> " # debug_show (txHashes));

      /// get canister id and generate if need it
      let cid: T.CanisterId = switch(currentCanisterid) {
        case(null) {
          /// generate canister
          currentCanisterid := await _createCanister();
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
            currentCanisterid := await _createCanister();
            switch(currentCanisterid) {
              case(null) throw Error.reject(errorText);
              case(?cid) cid;
            };
          }
        };
      };

      // register transaction
      let txId: T.TransactionId = await Transactions.canister(cid).registerTransaction(txInfo/* { txInfo with txHash } */);

      transactionsDirectory.put(txId, cid);
      txId
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };

  public shared({ caller }) func getLedgerTransactions(page: ?Nat, length: ?Nat, mwhRange: ?[T.TokenAmount], rangeDates: ?[Text], tokenId: ?T.TokenId) : async {
    data: [T.TransactionInfo];
    totalPages: Nat;
  } {
    _callValidation(caller);

    Debug.print(debug_show ("before getOutTransactions: " # Nat.toText(Cycles.balance())));

    // define page based on statement
    let startPage: Nat = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength: Nat = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i: Nat = startPage;

    // convert transactionsDirectory
    let directory: HM.HashMap<T.CanisterId, [T.TransactionId]> = HM.HashMap(50, Principal.equal, Principal.hash);

    // TODO evaluate if can implements filter by rangeDate in transactionDirectory instead of into Transactions.canister()
    while (i >= startIndex and i < startIndex + maxLength) {
      switch(transactionsDirectory.get(Nat.toText(i))) {
        case (null) {};
        case(?cid) {
          let tempTxIds = switch(directory.get(cid)) {
            case(null) Buffer.Buffer<T.TransactionId>(50);
            case(?value) Buffer.fromArray<T.TransactionId>(value);
          };
          tempTxIds.add(Nat.toText(i));

          directory.put(cid, Buffer.toArray(tempTxIds));
        };
      };

      i += 1;
    };


    var txFiltered: [T.TransactionInfo] = [];

    // iterate canisters to get transactions supplied
    for((cid, txIds) in directory.entries()) {
      let transactions: [T.TransactionInfo] = await Transactions.canister(cid).getOutTransactionsById(txIds, mwhRange, rangeDates, tokenId);
      txFiltered := Array.flatten<T.TransactionInfo>([txFiltered, transactions]);
    };

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    Debug.print(debug_show ("later getOutTransactions: " # Nat.toText(Cycles.balance())));

    { data = Array.reverse(txFiltered); totalPages };
  };

  public shared({ caller }) func getPlatformTransactions(page: ?Nat, length: ?Nat, mwhRange: ?[T.TokenAmount], rangeDates: ?[Text], tokenId: ?T.TokenId) : async {
    data: [T.TransactionInfo];
    totalPages: Nat;
  } {
    _callValidation(caller);

    Debug.print(debug_show ("before getPlatformTransactions: " # Nat.toText(Cycles.balance())));

    // define page based on statement
    let startPage: Nat = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength: Nat = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i: Nat = startPage;

    // convert transactionsDirectory
    let directory: HM.HashMap<T.CanisterId, [T.TransactionId]> = HM.HashMap(50, Principal.equal, Principal.hash);

    // TODO evaluate if can implements filter by rangeDate in transactionDirectory instead of into Transactions.canister()
    while (i >= startIndex and i < startIndex + maxLength) {
      switch(transactionsDirectory.get(Nat.toText(i))) {
        case (null) {};
        case(?cid) {
          let tempTxIds = switch(directory.get(cid)) {
            case(null) Buffer.Buffer<T.TransactionId>(50);
            case(?value) Buffer.fromArray<T.TransactionId>(value);
          };
          tempTxIds.add(Nat.toText(i));

          directory.put(cid, Buffer.toArray(tempTxIds));
        };
      };

      i += 1;
    };


    var txFiltered: [T.TransactionInfo] = [];

    // iterate canisters to get transactions supplied
    for((cid, txIds) in directory.entries()) {
      let transactions: [T.TransactionInfo] = await Transactions.canister(cid).getTransactionsById(txIds, null, null, mwhRange, null, rangeDates, tokenId);
      txFiltered := Array.flatten<T.TransactionInfo>([txFiltered, transactions]);
    };

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    Debug.print(debug_show ("later getPlatformTransactions: " # Nat.toText(Cycles.balance())));

    { data = Array.reverse(txFiltered); totalPages };
  };

  /// get transactions by tx id
  public shared({ caller }) func getTransactionsById(txIds: [T.TransactionId], txType: ?T.TxType, priceRange: ?[T.Price], mwhRange: ?[T.TokenAmount], method: ?T.TxMethod, rangeDates: ?[Text], tokenId: ?T.TokenId) : async [T.TransactionInfo] {
    _callValidation(caller);

    var txs: [T.TransactionInfo] = [];

    Debug.print(debug_show ("before getTransactionsById: " # Nat.toText(Cycles.balance())));

    // convert transactionsDirectory
    let directory: HM.HashMap<T.CanisterId, [T.TransactionId]> = HM.HashMap(50, Principal.equal, Principal.hash);
    for(txId in txIds.vals()) {
      switch(transactionsDirectory.get(txId)) {
        case (null) {};
        case(?cid) {
          let tempTxIds = switch(directory.get(cid)) {
            case(null) Buffer.Buffer<T.TransactionId>(50);
            case(?value) Buffer.fromArray<T.TransactionId>(value);
          };
          tempTxIds.add(txId);

          directory.put(cid, Buffer.toArray(tempTxIds));
        };
      };
    };

    // iterate canisters to get transactions supplied
    for((cid, txIds) in directory.entries()) {
      let transactions: [T.TransactionInfo] = await Transactions.canister(cid).getTransactionsById(txIds, txType, priceRange, mwhRange, method, rangeDates, tokenId);
      txs := Array.flatten<T.TransactionInfo>([txs, transactions]);
    };

    Debug.print(debug_show ("later getTransactionsById: " # Nat.toText(Cycles.balance())));

    txs
  };


  // /// used to get all transactions on Cero Trade
  // public shared({ caller }) func getTransactions(page: ?Nat, length: ?Nat, txType: ?T.TxType) : async {
  //   data: [T.TransactionInfo];
  //   totalPages: Nat;
  // } {
  //   _callValidation(caller);

  //   // define page based on statement
  //   let startPage = switch(page) {
  //     case(null) 1;
  //     case(?value) value;
  //   };

  //   // define length based on statement
  //   let maxLength = switch(length) {
  //     case(null) 50;
  //     case(?value) value;
  //   };

  //   let txs = Buffer.Buffer<T.TransactionInfo>(50);

  //   // calculate range of elements returned
  //   let startIndex: Nat = (startPage - 1) * maxLength;
  //   var i = 0;

  //   Debug.print(debug_show ("before getTransactions: " # Nat.toText(Cycles.balance())));

  //   // recopile and group txs
  //   let txsInCanister: HM.HashMap<T.CanisterId, [T.TransactionId]> = HM.HashMap(16, Principal.equal, Principal.hash);

  //   var cidTemp: ?T.CanisterId = null;
  //   let txIdsTemp = Buffer.Buffer<T.TransactionId>(50);

  //   for((txId, cid) in transactionsDirectory.entries()) {
  //     if (i >= startIndex and i < startIndex + maxLength) {
  //       if (cidTemp != ?cid) txIdsTemp.clear();
  //       cidTemp := ?cid;
  //       txIdsTemp.add(txId);

  //       txsInCanister.put(cid, Buffer.toArray<T.TransactionId>(txIdsTemp));
  //     };
  //     i += 1;
  //   };
  //   txIdsTemp.clear();


  //   // get transactions
  //   for((cid, txIds) in txsInCanister.entries()) {
  //     let transactions: [T.TransactionInfo] = await Transactions.canister(cid).getTransactionsById(txIds, txType);
  //     txs.append(Buffer.fromArray<T.TransactionInfo>(transactions));
  //   };

  //   Debug.print(debug_show ("later getTransactions: " # Nat.toText(Cycles.balance())));

  //   var totalPages: Nat = i / maxLength;
  //   if (totalPages <= 0) totalPages := 1;

  //   {
  //     data = Buffer.toArray<T.TransactionInfo>(txs);
  //     totalPages;
  //   }
  // };
}
