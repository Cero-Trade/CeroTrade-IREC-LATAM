import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Serde "mo:serde";
import Debug "mo:base/Debug";

// interfaces
import Users "../users/users_interface";
import IC_MANAGEMENT "../ic_management_canister_interface";
import HTTP "../http_service/http_service_interface";

// types
import T "../types";
import ENV "../env";

actor class UserIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;

  // constants
  stable let alreadyExists = "User already exists on Cero Trade";
  stable let notExists = "User doesn't exists on Cero Trade";

  // types
  type ProfilePart = {
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

  var usersDirectory: HM.HashMap<T.UID, T.CanisterId> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var usersDirectoryEntries : [(T.UID, T.CanisterId)] = [];

  stable var currentCanisterid: ?T.CanisterId = null;


  /// funcs to persistent collection state
  system func preupgrade() { usersDirectoryEntries := Iter.toArray(usersDirectory.entries()) };
  system func postupgrade() {
    usersDirectory := HM.fromIter<T.UID, T.CanisterId>(usersDirectoryEntries.vals(), 16, Principal.equal, Principal.hash);
    usersDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) {
    let authorizedCanisters = [
      ENV.CANISTER_ID_AGENT,
      ENV.CANISTER_ID_HTTP_SERVICE,
    ];

    assert Array.find<Text>(authorizedCanisters, func x = Principal.fromText(x) == caller) != null;
  };

  /// get size of usersDirectory collection
  public query func length(): async Nat { usersDirectory.size() };

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
    wasm_module := await IC_MANAGEMENT.getWasmModule(#users("users"));

    // update deployed canisters
    let deployedCanisters = Buffer.Buffer<T.CanisterId>(50);
    for (cid in usersDirectory.vals()) {
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
  };

  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool { usersDirectory.get(uid) != null };


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
          for (cid in usersDirectory.vals()) {
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
        for (cid in usersDirectory.vals()) {
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
        usersDirectory.remove(canister_id);
      };
      case(null) {
        for(canister_id in usersDirectory.vals()) {
          Cycles.add<system>(T.cycles);
          await IC_MANAGEMENT.ic.stop_canister({ canister_id });
          await IC_MANAGEMENT.ic.delete_canister({ canister_id });
          usersDirectory.remove(canister_id);
        };
      };
    };
  };

  /// returns true if canister have storage memory,
  /// false if havent enough
  public func checkMemoryStatus() : async Bool {
    let status = switch(currentCanisterid) {
      case(null) throw Error.reject("Cant find users canisters registered");
      case(?cid) await IC_MANAGEMENT.ic.canister_status({ canister_id = cid });
    };

    status.memory_size > IC_MANAGEMENT.LOW_MEMORY_LIMIT
  };

  /// autonomous function, will be executed when current canister it is full
  private func _createCanister<system>(): async ?T.CanisterId {
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

    return ?canister_id
  };

  private func _deleteUserWeb2(token: Text): async() {
    let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "users/delete";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(token)];
        bodyJson = "{}";
      });
  };

  public shared({ caller }) func getUsersInCeroTrade(): async [{
    principal: T.UID;
    canister: T.CanisterId;
    token: T.UserToken;
  }] {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    let users = Buffer.Buffer<{ principal: T.UID; canister: T.CanisterId; token: T.UserToken; }>(16);

    for((principal, canister) in usersDirectory.entries()) {
      let token = await Users.canister(canister).getUserToken(principal);
      users.add({ principal; canister; token })
    };

    Buffer.toArray<{ principal: T.UID; canister: T.CanisterId; token: T.UserToken; }>(users);
  };

  // ======================================================================================================== //

  /// register [usersDirectory] collection
  public shared({ caller }) func registerUser(uid: T.UID, form: T.RegisterForm, beneficiary: ?T.BID) : async() {
    _callValidation(caller);

    if (usersDirectory.get(uid) != null) throw Error.reject(alreadyExists);

    let formData = {
      principalId = Principal.toText(uid);
      companyId = form.companyId;
      evidentId = form.evidentId;
      companyName = form.companyName;
      country = form.country;
      city = form.city;
      address = form.address;
      email = form.email;
    };

    let formBlob = to_candid(formData);
    let formKeys = ["principalId", "companyId", "evidentId", "companyName", "country", "city", "address", "email"];

    // WARN just for debug
    Debug.print("registerUser with principal --> " # Principal.toText(uid));

    // tokenize userInfo in web2 backend
    let token = await HTTP.canister.post({
        url = HTTP.apiUrl # "users/store";
        port = null;
        uid = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
    let trimmedToken = Text.trimEnd(Text.trimStart(token, #char '\"'), #char '\"');

    // WARN just for debug
    Debug.print("token generated by user " # Principal.toText(uid) #" --> " # trimmedToken);

    try {
      let errorText = "Error generating canister";

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

      // register user
      await Users.canister(cid).registerUser(uid, trimmedToken);

      usersDirectory.put(uid, cid);

      switch(beneficiary) {
        case(null) {};
        case(?value) {
          // check if user exists
          if (await checkPrincipal(value)) await updateBeneficiaries(uid, value, { delete = false });
        };
      };
    } catch (error) {
      Debug.print("error here: " # debug_show(Error.message(error)));

      await _deleteUserWeb2(trimmedToken);

      throw Error.reject(Error.message(error));
    };
  };

  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(uid: T.UID, avatar: T.ArrayFile): async() {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).storeCompanyLogo(uid, avatar);
    };
  };

  /// update user into Cero Trade
  public shared({ caller }) func updateUserInfo(uid: T.UID, form: T.UpdateUserForm) : async() {
    _callValidation(caller);

    let cid = switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?value) value;
    };

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

    let token = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };

    // update user info in web2 database
    let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "users/update";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(token)];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
  };

  /// delete user to Cero Trade
  public shared({ caller }) func deleteUser(uid: T.UID): async() {
    _callValidation(caller);

    let cid: T.CanisterId = switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?cid) cid;
    };

    let token = await Users.canister(cid).getUserToken(uid);

    await _deleteUserWeb2(token);

    await Users.canister(cid).deleteUser(uid);

    let _ = usersDirectory.remove(uid);
  };
  
  /// get user token
  public shared({ caller }) func getUserToken(uid: T.UID): async T.UserToken {
    _callValidation(caller);

    let cid: T.CanisterId = switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?cid) cid;
    };

    await Users.canister(cid).getUserToken(uid);
  };

  /// get canister id that allow current user
  public shared({ caller }) func getUserCanister(uid: T.UID) : async T.CanisterId {
    _callValidation(caller);

    switch (usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case (?cid) cid;
    };
  };

  // update user transactions
  public shared({ caller }) func updateTransactions(uid: T.UID, recipent: ?T.BID, txId: T.TransactionId) : async() {
    _callValidation(caller);

    let currentToken = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };

    let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "web3-transactions";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(currentToken)];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          recipent = switch(recipent) {
            case(null) "";
            case(?value) Principal.toText(value);
          };
          txId;
        }), ["recipent", "txId"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
  };


  /// get profile information
  public shared({ caller }) func getProfile(uid: T.UID): async T.UserProfile {
    _callValidation(caller);

    let cid: T.CanisterId = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) cid;
    };

    let currentToken = await Users.canister(cid).getUserToken(uid);
    let profileJson = await HTTP.canister.get({
      url = HTTP.apiUrl # "users/retrieve/";
      port = null;
      uid = null;
      headers = [HTTP.tokenAuth(currentToken)]
    });
    let companyLogo = await Users.canister(cid).getCompanyLogo(uid);

    switch(Serde.JSON.fromText(profileJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");

      case(#ok(blob)) {
        let profilePart: ?ProfilePart = from_candid(blob);

        switch(profilePart) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?profile) return {
            companyLogo;
            principalId = profile.principalId;
            companyId = profile.companyId;
            companyName = profile.companyName;
            city = profile.city;
            country = profile.country;
            address = profile.address;
            email = profile.email;
            createdAt = profile.createdAt;
            updatedAt = profile.updatedAt;
          };
        };
      };
    };
  };

  /// get transaction user ids
  public shared({ caller }) func getTransactionIds(uid: T.UID): async [T.TransactionId] {
    _callValidation(caller);

    let currentToken = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };

    let transactions = await HTTP.canister.get({
        url = HTTP.apiUrl # "web3-transactions";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(currentToken)];
      });

    switch(Serde.JSON.fromText(transactions, null)) {
      case(#err(_)) throw Error.reject("cannot serialize transactions data");

      case(#ok(blob)) {
        let transactionIds: ?{transactions: [T.TransactionId]} = from_candid(blob);

        switch(transactionIds) {
          case(null) throw Error.reject("cannot serialize transactions data");
          case(?txs) txs.transactions;
        };
      };
    };
  };


  /// get beneficiaries
  public shared({ caller }) func getBeneficiaries(uid: T.UID): async [T.UserProfile] {
    _callValidation(caller);

    let currentToken = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };

    let beneficiaries = await HTTP.canister.get({
        url = HTTP.apiUrl # "users/beneficiaries";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(currentToken)];
      });


    switch(Serde.JSON.fromText(beneficiaries, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");

      case(#ok(blob)) {
        let profileParts: ?{beneficiaries: [ProfilePart]} = from_candid(blob);

        switch(profileParts) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?profiles) await buildUserProfiles(profiles.beneficiaries);
        };
      };
    };
  };

  public shared({ caller }) func checkBeneficiary(uid: T.UID, beneficiaryId: T.BID): async Bool {
    _callValidation(caller);

    let currentToken = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };

    let beneficiaryExists = await HTTP.canister.get({
        url = HTTP.apiUrl # "users/beneficiaries/check/" # Principal.toText(beneficiaryId);
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(currentToken)];
      });

    beneficiaryExists == "true";
  };


  // build [T.UserProfile] array from [ProfilePart]
  private func buildUserProfiles(profiles: [ProfilePart]): async [T.UserProfile] {
    let users = HM.HashMap<Text, T.UserProfile>(16, Text.equal, Text.hash);

    for(profile in profiles.vals()) {
      let uid = Principal.fromText(profile.principalId);

      switch(usersDirectory.get(uid)) {
        case (null) {};
        case(?cid) {
          let companyLogo = await Users.canister(cid).getCompanyLogo(uid);

          users.put(profile.principalId, {
            companyLogo;
            principalId = profile.principalId;
            companyId = profile.companyId;
            companyName = profile.companyName;
            city = profile.city;
            country = profile.country;
            address = profile.address;
            email = profile.email;
            createdAt = profile.createdAt;
            updatedAt = profile.updatedAt;
          });
        };
      };
    };

    Iter.toArray(users.vals())
  };


  /// update user beneficiaries
  public shared({ caller }) func updateBeneficiaries(uid: T.UID, beneficiaryId: T.BID, deleteBeneficiary: { delete: Bool }): async() {
    _callValidation(caller);

    let currentToken = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };

    let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "users/beneficiaries";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(currentToken)];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          caller = Principal.toText(uid);
          beneficiary = Principal.toText(beneficiaryId);
          remove = deleteBeneficiary.delete;
        }), ["caller", "beneficiary", "remove"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
  };


  /// filter users on Cero Trade by name or principal id
  public shared({ caller }) func filterUsers(uid: T.UID, user: Text): async [T.UserProfile] {
    _callValidation(caller);

    let currentToken = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getUserToken(uid);
    };
    let usersJson = await HTTP.canister.post({
        url = HTTP.apiUrl # "users/filter";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(currentToken)];
        bodyJson = "{\"user\": \"" # user # "\"}";
      });

    switch(Serde.JSON.fromText(usersJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");

      case(#ok(blob)) {
        let profileParts: ?{ users: [ProfilePart] } = from_candid(blob);

        switch(profileParts) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?value) await buildUserProfiles(value.users);
        };
      };
    };
  };
}
