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
import Deque "mo:base/Deque";

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

  type UserIndexInfo = {
    companyName: Text;
    canister_id: T.CanisterId;
  };

  var usersDirectory: HM.HashMap<T.UID, UserIndexInfo> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var usersDirectoryEntries : [(T.UID, UserIndexInfo)] = [];

  let emptyUserCanisters = Deque.empty<T.CanisterId>();

  // stable var currentCanisterid: ?T.CanisterId = null;


  /// funcs to persistent collection state
  system func preupgrade() { usersDirectoryEntries := Iter.toArray(usersDirectory.entries()) };
  system func postupgrade() {
    usersDirectory := HM.fromIter<T.UID, UserIndexInfo>(usersDirectoryEntries.vals(), 16, Principal.equal, Principal.hash);
    usersDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) {
    let authorizedCanisters = [
      ENV.CANISTER_ID_AGENT,
      ENV.CANISTER_ID_HTTP_SERVICE,
      Principal.toText(Principal.fromActor(this)),
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
    for ({ canister_id } in usersDirectory.vals()) {
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
          for ({ canister_id; } in usersDirectory.vals()) {
            if (not(Buffer.contains<T.CanisterId>(deployedCanisters, canister_id, Principal.equal))) {
              deployedCanisters.append(Buffer.fromArray<T.CanisterId>([canister_id]));
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
        for ({ canister_id } in usersDirectory.vals()) {
          if (not(Buffer.contains<T.CanisterId>(deployedCanisters, canister_id, Principal.equal))) {
            Cycles.add<system>(T.cycles);
            await IC_MANAGEMENT.ic.stop_canister({ canister_id });
            deployedCanisters.add(canister_id);
          };
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

        for((uid, { canister_id = cid }) in usersDirectory.entries()) {
          if (cid == canister_id) return usersDirectory.delete(uid);
        };
      };
      case(null) {
        let deletedCanisters = Buffer.Buffer<T.CanisterId>(16);

        for((uid, { canister_id }) in usersDirectory.entries()) {
          let canisterIsDeleted = Buffer.contains<T.CanisterId>(deletedCanisters, canister_id, Principal.equal);
          if (not canisterIsDeleted) {
            Cycles.add<system>(T.cycles);
            await IC_MANAGEMENT.ic.stop_canister({ canister_id });
            await IC_MANAGEMENT.ic.delete_canister({ canister_id });
            deletedCanisters.add(canister_id);
          };

          usersDirectory.delete(uid);
        };
      };
    };
  };

  /// returns true if canister have storage memory,
  /// false if havent enough
  // public func checkMemoryStatus() : async Bool {
  //   let status = switch(currentCanisterid) {
  //     case(null) throw Error.reject("Cant find users canisters registered");
  //     case(?cid) await IC_MANAGEMENT.ic.canister_status({ canister_id = cid });
  //   };

  //   status.memory_size > IC_MANAGEMENT.LOW_MEMORY_LIMIT
  // };

  /// autonomous function, will be executed when current canister it is full
  private func _createCanister<system>(): async T.CanisterId {
    switch(Deque.popBack(emptyUserCanisters)) {
      case(?cid) cid.1;

      case(null) {
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
    };
  };

  public shared({ caller }) func getUsersInCeroTrade(): async [{
    principal: T.UID;
    canister_id: T.CanisterId;
    token: T.UserTokenAuth;
  }] {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    let users = Buffer.Buffer<{ principal: T.UID; canister_id: T.CanisterId; token: T.UserTokenAuth; }>(16);

    for((principal, { canister_id }) in usersDirectory.entries()) {
      let token = await Users.canister(canister_id).getUserToken();
      users.add({ principal; canister_id; token })
    };

    Buffer.toArray<{ principal: T.UID; canister_id: T.CanisterId; token: T.UserTokenAuth; }>(users);
  };

  /// get canister id that allow current user
  private func getUserCanister(uid: T.UID): async Users.Users {
    switch (usersDirectory.get(uid)) {
      case (null) throw Error.reject(notExists);
      case (?{ canister_id }) Users.canister(canister_id);
    };
  };

  // ======================================================================================================== //
  // ======================================== Profile ===================================================== //
  // ======================================================================================================== //

  // Temporary deprecated, this function would be used to checkout canisters memory

  // private func saved(): async () {
  //   /// get canister id and generate if need it
  //   let cid: T.CanisterId = switch(currentCanisterid) {
  //     case(null) {
  //       /// generate canister
  //       currentCanisterid := await _createCanister();
  //       switch(currentCanisterid) {
  //         case(null) throw Error.reject(errorText);
  //         case(?cid) cid;
  //       };
  //     };
  //     case(?cid) {
  //       /// validate canister capability
  //       let haveMemory = await checkMemoryStatus();
  //       if (haveMemory) { cid } else {
  //         /// generate canister
  //         currentCanisterid := await _createCanister();
  //         switch(currentCanisterid) {
  //           case(null) throw Error.reject(errorText);
  //           case(?cid) cid;
  //         };
  //       }
  //     };
  //   };
  // };

  private func _deleteUserWeb2(token: Text): async() {
    let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "users/delete";
        port = null;
        uid = null;
        headers = [HTTP.tokenAuth(token)];
        bodyJson = "{}";
      });
  };

  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(uid: T.UID, avatar: T.ArrayFile): async() {
    _callValidation(caller);
    await (await getUserCanister(uid)).storeCompanyLogo(avatar);
  };

  /// register [usersDirectory] collection
  public shared({ caller }) func registerUser(uid: T.UID, form: T.RegisterForm, beneficiary: ?T.BID) : async() {
    _callValidation(caller);

    if (usersDirectory.get(uid) != null) throw Error.reject(alreadyExists);
    
    let checkedBeneficiary: ?T.BID = switch(beneficiary) {
      case(null) null;
      case(?value) {
        // check if user exists
        if (await checkPrincipal(value)) ?value
        else throw Error.reject("Beneficiary provided not exists in Cero Trade")
      };
    };

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
    // TODO commented while API be updated
    // let formData = {
    //   principalId = Principal.toText(uid);
    //   evidentId = form.evidentId;
    // };

    // let formBlob = to_candid(formData);
    // let formKeys = ["principalId", "evidentId"];

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

    let canister_id = await _createCanister();

    await Users.canister(canister_id).createProfile({
      companyLogo = null;
      vaultToken = trimmedToken;
      principal = uid;
      companyId = form.companyId;
      companyName = form.companyName;
      country = form.country;
      city = form.city;
      address = form.address;
      email = form.email;
    });

    usersDirectory.put(uid, { canister_id; companyName = form.companyName });

    switch(checkedBeneficiary) {
      case(null) {};
      case(?value) await addBeneficiary(uid, value);
    };
  };

  /// update user into Cero Trade
  public shared({ caller }) func updateUserInfo(uid: T.UID, form: T.UpdateUserForm) : async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).updateProfile({ form with principalId = Principal.toText(uid); });
  };

  /// delete user to Cero Trade
  public shared({ caller }) func deleteUser<system>(uid: T.UID): async() {
    _callValidation(caller);

    let canister_id: T.CanisterId = switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?{ canister_id }) canister_id;
    };

    let token = await Users.canister(canister_id).getUserToken();

    await _deleteUserWeb2(token);

    Cycles.add<system>(T.cycles);
    await IC_MANAGEMENT.ic.install_code({
      arg = to_candid();
      wasm_module;
      mode = #reinstall;
      canister_id;
    });
    usersDirectory.delete(uid);

    let _ = Deque.pushFront<T.CanisterId>(emptyUserCanisters, canister_id);
  };
  
  /// get user token
  public shared({ caller }) func getUserToken(uid: T.UID): async T.UserTokenAuth {
    _callValidation(caller);
    await (await getUserCanister(uid)).getUserToken();
  };

  /// get profile information
  public shared({ caller }) func getUserName(uid: T.UID): async Text {
    _callValidation(caller);

    switch(usersDirectory.get(uid)) {
      case(null) throw Error.reject(notExists);
      case(?{ companyName }) companyName;
    };
  };

  /// get profile information
  public shared({ caller }) func getProfile(uid: T.UID): async T.UserProfile {
    _callValidation(caller);
    await (await getUserCanister(uid)).getProfile();
  };



  // ======================================================================================================== //
  // ======================================== Portfolio ===================================================== //
  // ======================================================================================================== //
  /// get user portfolio
  public shared({ caller }) func getPortfolio(uid: T.UID, page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    data: [T.Portfolio];
    totalPages: Nat;
  } {
    _callValidation(caller);

    await (await getUserCanister(uid)).getPortfolio(page, length, assetTypes, country, mwhRange);
  };
  
  /// get single portfolio
  public shared({ caller }) func getSinglePortfolio(uid: T.UID, tokenId: T.TokenId): async T.SinglePortfolio {
    _callValidation(caller);

    await (await getUserCanister(uid)).getSinglePortfolio(tokenId);
  };

  /// add portfolio
  public shared({ caller }) func addTokensPortfolio(uid: T.UID, assets: [T.AssetInfo]): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).addTokensPortfolio(assets);
  };

  /// remove portfolio
  public shared({ caller }) func removeTokensPortfolio(uid: T.UID, tokenIds: [T.TokenId]): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).removeTokensPortfolio(tokenIds);
  };

  /// update portfolio
  public shared({ caller }) func updatePortfolio(uid: T.UID, { tokenId: T.TokenId; inMarket: ?T.TokenAmount; redemption: ?T.TransactionInfo }): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).updatePortfolio({ tokenId: T.TokenId; inMarket: ?T.TokenAmount; redemption: ?T.TransactionInfo });
  };


  
  // ======================================================================================================== //
  // ======================================== Notifications ===================================================== //
  // ======================================================================================================== //
  // get notification
  public shared({ caller }) func getNotification(uid: T.UID, notificationId: T.NotificationId): async T.NotificationInfo {
    _callValidation(caller);
    await (await getUserCanister(uid)).getNotification(notificationId);
  };

  // get notifications
  public shared({ caller }) func getNotifications(uid: T.UID, page: ?Nat, length: ?Nat, notificationTypes: [T.NotificationType]): async {
    data: [T.NotificationInfo];
    totalPages: Nat;
  } {
    _callValidation(caller);
    await (await getUserCanister(uid)).getNotifications(page, length, notificationTypes);
  };

  // add notification
  public shared({ caller }) func addNotification(notification: T.NotificationInfo): async() {
    _callValidation(caller);

    let recieverCanister = await getUserCanister(notification.receivedBy);

    var receiverNotification = notification;
    var senderNotification = notification;

    switch(notification.notificationType) {
      case(#general(value)) {};

      case(#redeem(value)) switch(notification.triggeredBy) {
        case(null) {};

        case(?triggerUser) {
          let receiverCompanyName = switch(usersDirectory.get(notification.receivedBy)) {
            case(null) throw Error.reject("Receiver user not found");
            case(?{ companyName }) companyName;
          };
          let senderCompanyName = switch(usersDirectory.get(triggerUser)) {
            case(null) throw Error.reject("Trigger user not found");
            case(?{ companyName }) companyName;
          };
          let amount: Text = switch(notification.quantity) {
            case(null) "0";
            case(?value) await T.tokenToText(value, null);
          };

          // notification to receiver
          receiverNotification := { notification with content = ?("Request received from user " # senderCompanyName # " by amount " # amount) };
          // notification to sender
          senderNotification := { notification with content = ?("Request sended to user " # receiverCompanyName # " by amount " # amount) };
        };
      };

      case(#beneficiary(value)) switch(notification.triggeredBy) {
        case(null) {};

        case(?triggerUser) {
          let receiverCompanyName = switch(usersDirectory.get(notification.receivedBy)) {
            case(null) throw Error.reject("Receiver user not found");
            case(?{ companyName }) companyName;
          };
          let senderCompanyName = switch(usersDirectory.get(triggerUser)) {
            case(null) throw Error.reject("Trigger user not found");
            case(?{ companyName }) companyName;
          };

          // notification to receiver
          receiverNotification := { notification with content = ?("Request received from user " # senderCompanyName) };
          // notification to sender
          senderNotification := { notification with content = ?("Request sended to user " # receiverCompanyName) };
        };
      };
    };

    // add notification to receiver user
    let id = await recieverCanister.addNotification(receiverNotification);

    switch(notification.triggeredBy) {
      case(null) {};
      case(?uid) {
        // add notification to trigger user
        let _ = await (await getUserCanister(uid)).addNotification({ senderNotification with id});
      };
    };
  };

  // clear notifications
  public shared({ caller }) func clearNotifications(uid: T.UID, notificationIds: ?[T.NotificationId]): async() {
    _callValidation(caller);
    await (await getUserCanister(uid)).clearNotifications(notificationIds);
  };

  // update general
  public shared({ caller }) func updateGeneralNotifications(uid: T.UID, notificationIds: ?[T.NotificationId]): async() {
    _callValidation(caller);
    await (await getUserCanister(uid)).updateGeneral(notificationIds);
  };

  // update event
  public shared({ caller }) func updateEventNotification(userCaller: T.UID, notificationId: T.NotificationId, eventStatus: ?T.NotificationEventStatus): async ?T.NotificationInfo {
    _callValidation(caller);

    let userCanister = await getUserCanister(userCaller);
    let notification = await userCanister.getNotification(notificationId);

    // get other user canister
    let otherUserCanisterId = switch(usersDirectory.get(switch(userCaller == notification.receivedBy) {
      case(true) {
        switch(notification.triggeredBy) {
          case(null) throw Error.reject("triggeredBy not provided");
          case(?value) value;
        };
      };
      case(false) notification.receivedBy;
    })) {
      case(null) throw Error.reject("Beneficiary not exists on Cero Trade");
      case(?{ canister_id }) canister_id;
    };

    // variable to know which user has cancel
    var cancelRedemptionNotification: ?T.NotificationInfo = null;

    // change event notification status
    switch(eventStatus) {
      case(null) {};
      case(?value) {
        // validate if current notification is type redemption and was cancelled to return tokens holded
        if (notification.notificationType == #redeem("redeem") and notification.eventStatus == ?#pending("pending") and value == #declined("declined")) {
          cancelRedemptionNotification := ?notification;
        };

        await userCanister.clearNotifications(?[notificationId]);
        await Users.canister(otherUserCanisterId).updateEvent(notificationId, value);
      };
    };

    cancelRedemptionNotification
  };



  // ======================================================================================================== //
  // ======================================== Beneficiaries ===================================================== //
  // ======================================================================================================== //
  /// get beneficiaries
  public shared({ caller }) func getBeneficiaries(uid: T.UID): async [T.UserProfile] {
    _callValidation(caller);

    let beneficiaryIds = await (await getUserCanister(uid)).getBeneficiaries();
    let beneficiaries = Buffer.Buffer<T.UserProfile>(16);

    for(beneficiaryId in beneficiaryIds.vals()) {
      let beneficiary: T.UserProfile = await (await getUserCanister(beneficiaryId)).getProfile();
      beneficiaries.add(beneficiary);
    };

    Buffer.toArray<T.UserProfile>(beneficiaries);
  };

  public shared({ caller }) func checkBeneficiary(uid: T.UID, beneficiaryId: T.BID): async Bool {
    _callValidation(caller);
    await (await getUserCanister(uid)).checkBeneficiary(beneficiaryId);
  };

  /// add beneficiary to user
  public shared({ caller }) func addBeneficiary(uid: T.UID, beneficiaryId: T.BID): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).addBeneficiary(beneficiaryId);
    await (await getUserCanister(beneficiaryId)).addBeneficiary(uid);
  };

  /// remove beneficiary from user
  public shared({ caller }) func removeBeneficiary(uid: T.UID, beneficiaryId: T.BID): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).removeBeneficiary(beneficiaryId);
    await (await getUserCanister(beneficiaryId)).removeBeneficiary(uid);
  };


  /// filter users on Cero Trade by name or principal id
  public query func filterUsers(uid: T.UID, input: Text): async [{ principalId: T.UID; companyName: Text }] {
    // checkout caller exists on Cero Trade
    if (usersDirectory.get(uid) == null) throw Error.reject(notExists);

    let beneficiaries = Buffer.Buffer<{ principalId: T.UID; companyName: Text }>(16);

    for((principalId, { canister_id; companyName }) in usersDirectory.entries()) {
      let userInput = Text.toLowercase(input);
      let containsCompanyName = Text.contains(Text.toLowercase(companyName), #text userInput);
      let containsPrincipal = Text.contains(Principal.toText(principalId), #text userInput);

      if (containsCompanyName or containsPrincipal) { beneficiaries.add({ principalId; companyName }); };
    };

    Buffer.toArray<{ principalId: T.UID; companyName: Text }>(beneficiaries);
  };



  // ======================================================================================================== //
  // ======================================== Transactions ===================================================== //
  // ======================================================================================================== //
  /// get transactionIds from user
  public shared({ caller }) func getTransactionIds(uid: T.UID, page: ?Nat, length: ?Nat): async {
    data: [T.TransactionId];
    totalPages: Nat;
  } {
    _callValidation(caller);
    await (await getUserCanister(uid)).getTransactions(page, length);
  };

  /// add transactionId to user
  public shared({ caller }) func updateTransactions(uid: T.UID, recipent: ?T.BID, transactionId: T.TransactionId): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).addTransaction(transactionId);

    switch(recipent) {
      case(null) {};
      case(?value) await (await getUserCanister(value)).addTransaction(transactionId);
    };
  };

  /// add transactionId to user and update marketplace amount
  public shared({ caller }) func updateMarketplace(uid: T.UID, { amountInMarket: T.TokenAmount; transaction: T.TransactionInfo }, buyer: ?{ recipent: T.BID; assetInfo: T.AssetInfo }): async() {
    _callValidation(caller);

    // if not provide buyer will be updated [marketplace + transactions] of user
    //
    // else will be updated recipent marketplace and user [portfolio + transactions]
    switch(buyer) {
      case(null) await (await getUserCanister(uid)).updateMarketplaceWithTransaction(amountInMarket, transaction);

      case(?{ recipent; assetInfo; }) {
        // update marketplace of recipent
        await (await getUserCanister(recipent)).updatePortfolio({ tokenId = transaction.tokenId; inMarket = ?amountInMarket; redemption = null });

        // update portfolio + transactions of user
        await (await getUserCanister(uid)).addTokensWithTransaction(assetInfo, transaction.transactionId);
      }
    };
  };

  /// add transactionId to user and update redemptions
  public shared({ caller }) func updateRedemptions(uid: T.UID, recipent: ?T.BID, transaction: T.TransactionInfo): async() {
    _callValidation(caller);

    await (await getUserCanister(uid)).addTransaction(transaction.transactionId);

    switch(recipent) {
      case(null) {};
      case(?value) await (await getUserCanister(value)).updateRedemptions(transaction);
    };
  };
}
