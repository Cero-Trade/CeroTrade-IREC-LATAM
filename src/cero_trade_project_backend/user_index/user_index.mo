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

// canisters
import HttpService "canister:http_service";

// types
import T "../types";
import HT "../http_service/http_service_types";
import ENV "../env";

shared({ caller = adminCaller }) actor class UserIndex() = this {
  stable let ic : T.IC = actor ("aaaaa-aa");
  private func UsersCanister(cid: T.CanisterId): T.UsersInterface { actor (Principal.toText(cid)) };
  stable var wasm_array : [Nat] = [];


  // constants
  stable let alreadyExists = "User already exists on cero trade";
  stable let notExists = "User doesn't exists on cero trade";


  var usersDirectory: HM.HashMap<T.UID, T.CanisterId> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var usersDirectoryEntries : [(T.UID, T.CanisterId)] = [];

  stable var currentCanisterid: ?T.CanisterId = null;


  /// funcs to persistent collection state
  system func preupgrade() { usersDirectoryEntries := Iter.toArray(usersDirectory.entries()) };
  system func postupgrade() {
    usersDirectory := HM.fromIter<T.UID, T.CanisterId>(usersDirectoryEntries.vals(), 16, Principal.equal, Principal.hash);
    usersDirectoryEntries := [];
  };

  private func callValidation(caller: Principal) { assert Principal.fromText(ENV.AGENT_CANISTER_ID) == caller };
  private func adminValidation(caller: Principal) { assert adminCaller == caller };

  /// get size of usersDirectory collection
  public query func length(): async Nat { usersDirectory.size() };

  /// register wasm module to dynamic users canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    adminValidation(caller);

    let branch = switch(ENV.DFX_NETWORK) {
      case("ic") "main";
      case("local") "develop";
      case _ throw Error.reject("No DFX_NETWORK provided");
    };
    let wasmModule = await HttpService.get("https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # branch # "/wasm_modules/users.json", { headers = [] });

    let parts = Text.split(Text.replace(Text.replace(wasmModule, #char '[', ""), #char ']', ""), #char ',');
    wasm_array := Array.map<Text, Nat>(Iter.toArray(parts), func(part) {
      switch (Nat.fromText(part)) {
        case null 0;
        case (?n) n;
      }
    });
  };

  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool { usersDirectory.get(uid) != null };


  /// returns true if canister have storage memory,
  /// false if havent enough
  public shared({ caller }) func checkMemoryStatus() : async Bool {
    adminValidation(caller);

    let status = switch(currentCanisterid) {
      case(null) throw Error.reject("Cant find users canisters registered");
      case(?cid) await ic.canister_status({ canister_id = cid });
    };

    status.memory_size > T.LOW_MEMORY_LIMIT
  };

  /// autonomous function, will be executed when current canister it is full
  private func createCanister(): async ?T.CanisterId {
    Debug.print(debug_show ("before create_canister: " # Nat.toText(Cycles.balance())));

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

    let nums8 : [Nat8] = Array.map<Nat, Nat8>(wasm_array, Nat8.fromNat);

    await ic.install_code({
      arg = to_candid();
      wasm_module = Blob.fromArray(nums8);
      mode = #install;
      canister_id;
    });

    Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

    return ?canister_id
  };

  private func deleteUserWeb2(token: Text): async() {
    let formData = { token };
    let formBlob = to_candid(formData);
    let formKeys = ["token"];

    let res = await HttpService.post(HT.apiUrl # "users/delete", {
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
  };

  /// register [usersDirectory] collection
  public shared({ caller }) func registerUser(uid: T.UID, form: T.RegisterForm) : async() {
    callValidation(caller);

    // WARN just for debug
    Debug.print(Principal.toText(uid));

    if (usersDirectory.get(uid) != null) throw Error.reject(alreadyExists);

    let formData = {
      principalId = Principal.toText(uid);
      companyId = form.companyId;
      companyName = form.companyName;
      country = form.country;
      city = form.city;
      address = form.address;
      email = form.email;
    };

    let formBlob = to_candid(formData);
    let formKeys = ["principalId", "companyId", "companyName", "country", "city", "address", "email"];

    // tokenize userInfo in web2 backend
    let token = await HttpService.post(HT.apiUrl # "users/store", {
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
    let trimmedToken = Text.trimEnd(Text.trimStart(token, #char '\"'), #char '\"');

    // WARN just for debug
    Debug.print("token: " # trimmedToken);

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

      // register user
      await UsersCanister(cid).registerUser(uid, trimmedToken);

      usersDirectory.put(uid, cid);
    } catch (error) {
      await deleteUserWeb2(trimmedToken);

      throw Error.reject(Error.message(error));
    };
  };

  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(uid: T.UID, avatar: T.CompanyLogo): async() {
    callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?cid) await UsersCanister(cid).storeCompanyLogo(uid, avatar);
    };
  };

  /// delete user to cero trade
  public shared({ caller }) func deleteUser(uid: T.UID): async() {
    callValidation(caller);

    let cid: T.CanisterId = switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?cid) cid;
    };

    let token = await UsersCanister(cid).getUserToken(uid);

    await deleteUserWeb2(token);

    await UsersCanister(cid).deleteUser(uid);

    let _ = usersDirectory.remove(uid);
  };

  /// get canister id that allow current user
  public shared({ caller }) func getUserCanister(uid: T.UID) : async T.CanisterId {
    callValidation(caller);

    switch (usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case (?cid) cid;
    };
  };

  /// update user portfolio
  public shared({ caller }) func updatePorfolio(uid: T.UID, token: T.TokenId) : async() {
    callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await UsersCanister(cid).updatePorfolio(uid, token);
    };
  };

  // update user transactions
  public shared({ caller }) func updateTransactions(uid: T.UID, txId: T.TransactionId) : async() {
    callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await UsersCanister(cid).updateTransactions(uid, txId);
    };
  };


  /// get profile information
  public shared({ caller }) func getProfile(uid: T.UID): async T.UserProfile {
    callValidation(caller);

    let cid: T.CanisterId = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) cid;
    };

    let token = await UsersCanister(cid).getUserToken(uid);
    let profile = await HttpService.get(HT.apiUrl # "users/retrieve/" # token, { headers = [] });
    let companyLogo = await UsersCanister(cid).getCompanyLogo(uid);

    { companyLogo; profile; }
  };


  /// get portfolio information
  public shared({ caller }) func getPortfolioTokenIds(uid: T.UID): async [T.TokenId] {
    callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await UsersCanister(cid).getPortfolioTokenIds(uid);
    };
  };


  /// get transaction user ids
  public shared({ caller }) func getTransactionIds(uid: T.UID): async [T.TransactionId] {
    callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await UsersCanister(cid).getTransactionIds(uid);
    };
  };


  /// get user account ledger
  public shared({ caller }) func getUserLedger(uid: T.UID): async Blob {
    callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await UsersCanister(cid).getLedger(uid);
    };
  };
}
