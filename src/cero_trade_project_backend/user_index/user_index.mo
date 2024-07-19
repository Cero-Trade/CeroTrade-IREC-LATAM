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

// canisters
import HttpService "canister:http_service";

// interfaces
import IC_MANAGEMENT "../ic_management_canister_interface";
import Users "../users/users_interface";

// types
import T "../types";
import HT "../http_service/http_service_types";
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

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };

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

    let branch = switch(ENV.DFX_NETWORK) {
      case("ic") "main";
      case("local") "develop";
      case _ throw Error.reject("No DFX_NETWORK provided");
    };
    let wasmModule = await HttpService.get({
      url = "https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # branch # "/wasm_modules/users.json";
      port = null;
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

  /// returns true if canister have storage memory,
  /// false if havent enough
  public func checkMemoryStatus() : async Bool {
    let status = switch(currentCanisterid) {
      case(null) throw Error.reject("Cant find users canisters registered");
      case(?cid) await IC_MANAGEMENT.ic.canister_status({ canister_id = cid });
    };

    status.memory_size > T.LOW_MEMORY_LIMIT
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
    let formData = { token };
    let formBlob = to_candid(formData);
    let formKeys = ["token"];

    let _ = await HttpService.post({
        url = HT.apiUrl # "users/delete";
        port = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
  };

  /// register [usersDirectory] collection
  public shared({ caller }) func registerUser(uid: T.UID, form: T.RegisterForm, beneficiary: ?T.BID) : async() {
    _callValidation(caller);

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

    // WARN just for debug
    Debug.print(Principal.toText(uid));

    // tokenize userInfo in web2 backend
    let token = await HttpService.post({
        url = HT.apiUrl # "users/store";
        port = null;
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
  public shared({ caller }) func storeCompanyLogo(uid: T.UID, avatar: T.CompanyLogo): async() {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).storeCompanyLogo(uid, avatar);
    };
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

  /// update user portfolio
  public shared({ caller }) func updatePortfolio(uid: T.UID, token: T.TokenId, deletePortfolio: { delete: Bool }) : async() {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).updatePortfolio(uid, token, deletePortfolio);
    };
  };

  // update user transactions
  public shared({ caller }) func updateTransactions(uid: T.UID, txId: T.TransactionId) : async() {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).updateTransactions(uid, txId);
    };
  };


  /// get profile information
  public shared({ caller }) func getProfile(uid: T.UID): async T.UserProfile {
    _callValidation(caller);

    let cid: T.CanisterId = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) cid;
    };

    let token = await Users.canister(cid).getUserToken(uid);
    let profileJson = await HttpService.get({
      url = HT.apiUrl # "users/retrieve/" # token;
      port = null;
      headers = []
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


  /// get user profiles information
  public shared({ caller }) func getUsers(uids: [T.UID]): async [T.UserProfile] {
    _callValidation(caller);

    // check if user exists
    if (not (await checkPrincipal(caller))) throw Error.reject(notExists);

    let users = await HttpService.post({
        url = HT.apiUrl # "users/retrieve-list";
        port = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid(uids), ["tokenIds"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });

    switch(Serde.JSON.fromText(users, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");

      case(#ok(blob)) {
        let profileParts: ?[ProfilePart] = from_candid(blob);

        switch(profileParts) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?profiles) await buildUserProfiles(profiles);
        };
      };
    };
  };


  /// get portfolio information
  public shared({ caller }) func getPortfolioTokenIds(uid: T.UID): async [T.TokenId] {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getPortfolioTokenIds(uid);
    };
  };


  /// get transaction user ids
  public shared({ caller }) func getTransactionIds(uid: T.UID): async [T.TransactionId] {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getTransactionIds(uid);
    };
  };


  // TODO performe fix to replace beneficiary ids storage from web3 to web2

  /// get beneficiaries
  public shared({ caller }) func getBeneficiaries(uid: T.UID): async [T.UserProfile] {
    _callValidation(caller);

    let beneficiaryIds: [T.BID] = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getBeneficiaries(uid);
    };

    if (beneficiaryIds.size() == 0) return [];

    // TODO this endpoint is temporary
    let beneficiaries = await HttpService.post({
        url = HT.apiUrl # "users/retrieve-list";
        port = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          principalIds = Array.map<T.BID, Text>(beneficiaryIds, func x = Principal.toText(x))
        }), ["principalIds"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });


    switch(Serde.JSON.fromText(beneficiaries, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");

      case(#ok(blob)) {
        let profileParts: ?[ProfilePart] = from_candid(blob);

        switch(profileParts) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?profiles) await buildUserProfiles(profiles);
        };
      };
    };
  };

  // TODO this function is temporary
  public shared({ caller }) func checkBeneficiary(uid: T.UID, beneficiaryId: T.BID): async Bool {
    _callValidation(caller);

    var beneficiaryIds: [T.BID] = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getBeneficiaries(uid);
    };
    beneficiaryIds := Array.filter<T.BID>(beneficiaryIds, func x = x == beneficiaryId);

    beneficiaryIds.size() != 0;
  };

  /// get beneficiary
  public shared({ caller }) func getBeneficiary(uid: T.UID, beneficiaryId: T.BID): async T.UserProfile {
    _callValidation(caller);

    var beneficiaryIds: [T.BID] = switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).getBeneficiaries(uid);
    };
    beneficiaryIds := Array.filter<T.BID>(beneficiaryIds, func x = x == beneficiaryId);

    if (beneficiaryIds.size() == 0) throw Error.reject("Beneficiary not found");

    // TODO this endpoint is temporary
    let beneficiary = await HttpService.post({
        url = HT.apiUrl # "users/retrieve-list";
        port = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          principalIds = Array.map<T.BID, Text>(beneficiaryIds, func x = Principal.toText(x))
        }), ["principalIds"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });


    switch(Serde.JSON.fromText(beneficiary, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");

      case(#ok(blob)) {
        let profileParts: ?[ProfilePart] = from_candid(blob);

        let beneficiary = switch(profileParts) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?profiles) await buildUserProfiles(profiles);
        };

        beneficiary[0]
      };
    };
  };


  // build [T.UserProfile] array from [ProfilePart]
  private func buildUserProfiles(profiles: [ProfilePart]): async [T.UserProfile] {
    let users = Buffer.Buffer<(Text, T.CompanyLogo)>(16);

    for(profile in profiles.vals()) {
      let uid = Principal.fromText(profile.principalId);

      switch(usersDirectory.get(uid)) {
        case (null) {};
        case(?cid) {
          let companyLogo = await Users.canister(cid).getCompanyLogo(uid);
          users.add((profile.principalId, companyLogo));
        };
      };
    };

    // map profiles values to [UserProfile]
    return Array.map<ProfilePart, T.UserProfile>(profiles, func (item) {
      let principalId = item.principalId;
      let user = Array.find<(Text, T.CompanyLogo)>(Buffer.toArray<(Text, T.CompanyLogo)>(users), func (element) { element.0 == principalId });

      switch(user) {
        /// this case will not occur, just here to can compile
        case(null) {
          {
            companyLogo = [];
            principalId;
            companyId = item.companyId;
            companyName = item.companyName;
            city = item.city;
            country = item.country;
            address = item.address;
            email = item.email;
            createdAt = item.createdAt;
            updatedAt = item.updatedAt;
          }
        };

        // build [UserProfile] object
        case(?value) {
          {
            companyLogo = value.1;
            principalId;
            companyId = item.companyId;
            companyName = item.companyName;
            city = item.city;
            country = item.country;
            address = item.address;
            email = item.email;
            createdAt = item.createdAt;
            updatedAt = item.updatedAt;
          }
        };
      };
    })
  };


  /// update user beneficiaries
  public shared({ caller }) func updateBeneficiaries(uid: T.UID, beneficiaryId: T.BID, deleteBeneficiary: { delete: Bool }): async() {
    _callValidation(caller);

    // update caller collection
    switch(usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).updateBeneficiaries(uid, beneficiaryId, deleteBeneficiary);
    };

    // update beneficiary collection
    switch(usersDirectory.get(beneficiaryId)) {
      case (null) throw Error.reject(notExists);
      case(?cid) await Users.canister(cid).updateBeneficiaries(beneficiaryId, uid, deleteBeneficiary);
    };
  };


  /// filter users on Cero Trade by name or principal id
  public shared({ caller }) func filterUsers(uid: T.UID, user: Text): async [T.UserProfile] {
    _callValidation(caller);

    // check if user exists
    if (not (await checkPrincipal(uid))) throw Error.reject(notExists);

    let usersJson = await HttpService.post({
        url = HT.apiUrl # "users/filter";
        port = null;
        headers = [];
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
