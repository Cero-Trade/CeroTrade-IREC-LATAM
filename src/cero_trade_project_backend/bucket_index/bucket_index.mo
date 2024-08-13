import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Serde "mo:serde";
import Debug "mo:base/Debug";

// interfaces
import IC_MANAGEMENT "../ic_management_canister_interface";
import Bucket "../bucket/bucket_interface";

// types
import T "../types";
import ENV "../env";

actor class BucketIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;

  var bucketDirectory: HM.HashMap<T.CanisterId, [T.BucketId]> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var bucketDirectoryEntries : [(T.CanisterId, [T.BucketId])] = [];


  /// funcs to persistent collection state
  system func preupgrade() { bucketDirectoryEntries := Iter.toArray(bucketDirectory.entries()) };
  system func postupgrade() {
    bucketDirectory := HM.fromIter<T.CanisterId, [T.BucketId]>(bucketDirectoryEntries.vals(), 16, Principal.equal, Principal.hash);
    bucketDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };

  /// get size of bucketDirectory collection
  public query func length(): async Nat { bucketDirectory.size() };


  /// get canister controllers
  public shared({ caller }) func getControllers(): async ?[Principal] {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    await IC_MANAGEMENT.getControllers(Principal.fromActor(this));
  };

  /// register canister controllers
  public shared({ caller }) func registerControllers(): async () {
    _callValidation(caller);

    controllers := await IC_MANAGEMENT.getControllers(Principal.fromActor(this));
  };

  /// register wasm module to dynamic users canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    _callValidation(caller);

    // register wasm
    wasm_module := await IC_MANAGEMENT.getWasmModule(#bucket("bucket"));

    // update deployed canisters
    for (canister_id in bucketDirectory.keys()) {
      await IC_MANAGEMENT.ic.install_code({
        arg = to_candid();
        wasm_module;
        mode = #upgrade;
        canister_id;
      });
    };
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
          for (cid in bucketDirectory.keys()) {
            if (not(Buffer.contains<T.CanisterId>(deployedCanisters, cid, Principal.equal))) {
              deployedCanisters.append(Buffer.fromArray<T.CanisterId>([cid]));
            };
          };

          for(canister_id in deployedCanisters.vals()) {
            Cycles.add<system>(T.cycles);
            await IC_MANAGEMENT.ic.start_canister({ canister_id });
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
        for (cid in bucketDirectory.keys()) {
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

  /// returns true if canister have storage memory,
  /// false if havent enough
  public func checkMemoryStatus(canister_id: T.CanisterId) : async Bool {
    switch(bucketDirectory.get(canister_id)) {
      case(null) throw Error.reject("Cant find notifications canisters registered");
      case(?values) {
        let { memory_size } = await IC_MANAGEMENT.ic.canister_status({ canister_id });
        memory_size > IC_MANAGEMENT.LOW_MEMORY_LIMIT
      };
    };
  };

  /// autonomous function to create canister
  public func _createCanister<system>(): async Principal {
    Debug.print(debug_show ("before create_canister: " # Nat.toText(Cycles.balance())));

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

    await IC_MANAGEMENT.ic.install_code({
      arg = to_candid();
      wasm_module;
      mode = #install;
      canister_id;
    });

    Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

    return canister_id
  };

  private func getAvailableCanister(): async (T.CanisterId, [T.BucketId]) {
    var selectedCanister: ?(T.CanisterId, [T.BucketId]) = null;

    let entries = bucketDirectory.entries();

    // recursive function to know if canisterId have memory
    func checkCanisters() : async ?(T.CanisterId, [T.BucketId]) {
      switch (entries.next()) {
        case (null) null;
        case (?(cid, notifications)) {
          let haveMemory = await checkMemoryStatus(cid);
          if (haveMemory) { ?(cid, notifications) }
          else { await checkCanisters() };
        };
      };
    };

    selectedCanister := await checkCanisters();

    if (selectedCanister == null) {
      // otherwise, if canister haveNotMemory
      let cid = await _createCanister();
      selectedCanister := ?(cid, []);
    };

    // return canister
    switch (selectedCanister) {
      case (null) throw Error.reject("Bucket canister not found");
      case (?value) value;
    };
  };

  // ================================================================================== //

  /// add file to [bucketDirectory] collection
  public shared({ caller }) func addFile(bucketId: T.BucketId, file: T.ArrayFile) : async() {
    _callValidation(caller);

    try {
      let (cid, bucketIds) = await getAvailableCanister();

      // add file
      await Bucket.canister(cid).addFile(bucketId, file);

      let bucketCopy = Buffer.fromArray<T.BucketId>(bucketIds);
      bucketCopy.add(bucketId);

      bucketDirectory.put(cid, Buffer.toArray<T.BucketId>(bucketCopy));
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };

  // get file from bucket
  public shared({ caller }) func getFile(bucketId: T.BucketId): async (T.CanisterId, T.ArrayFile) {
    _callValidation(caller);

    // iterate bucket on directory
    for((cid, bucketIds) in bucketDirectory.entries()) {
      switch(Array.find<T.BucketId>(bucketIds, func id = id == bucketId)) {
        case(null) {};
        case(?value) {
          let file = await Bucket.canister(cid).getFile(value);

          return (cid, file)
        };
      };
    };

    throw Error.reject("File not found");
  };

  // get files from bucket
  public shared({ caller }) func getFiles(bucketIds: [T.BucketId]): async [T.ArrayFile] {
    _callValidation(caller);

    // Convert bucketIds to a HashMap for faster lookup
    let bucketMap = HM.fromIter<T.BucketId, Null>(Iter.fromArray(Array.map<T.BucketId, (T.BucketId, Null)>(bucketIds, func id = (id, null))), 16, Text.equal, Text.hash);

    var bucket: [T.ArrayFile] = [];

    // iterate files on directory
    for((cid, files) in bucketDirectory.entries()) {
      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.BucketId>(files, func id = bucketMap.get(id) != null);

      if (filteredIds.size() > 0) {
        let files = await Bucket.canister(cid).getFiles(filteredIds);
        bucket := Array.flatten<T.ArrayFile>([bucket, files]);
      }
    };

    bucket
  };
}
