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
import Notifications "../notifications/notifications_interface";

// types
import T "../types";
import HT "../http_service/http_service_types";
import ENV "../env";

actor class NotificationIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;

  var notificationsDirectory: HM.HashMap<T.CanisterId, [T.NotificationId]> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var notificationsDirectoryEntries : [(T.CanisterId, [T.NotificationId])] = [];


  /// funcs to persistent collection state
  system func preupgrade() { notificationsDirectoryEntries := Iter.toArray(notificationsDirectory.entries()) };
  system func postupgrade() {
    notificationsDirectory := HM.fromIter<T.CanisterId, [T.NotificationId]>(notificationsDirectoryEntries.vals(), 16, Principal.equal, Principal.hash);
    notificationsDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };

  /// get size of notificationsDirectory collection
  public query func length(): async Nat { notificationsDirectory.size() };


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
    let wasmModule = await HttpService.get("https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # branch # "/wasm_modules/notifications.json", { headers = [] });

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
    for (canister_id in notificationsDirectory.keys()) {
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
        Cycles.add<system>(20_949_972_000);
        await IC_MANAGEMENT.ic.start_canister({ canister_id });
      };
      case(null) {
        let deployedCanisters = Buffer.Buffer<T.CanisterId>(50);
          for (cid in notificationsDirectory.keys()) {
            if (not(Buffer.contains<T.CanisterId>(deployedCanisters, cid, Principal.equal))) {
              deployedCanisters.append(Buffer.fromArray<T.CanisterId>([cid]));
            };
          };

          for(canister_id in deployedCanisters.vals()) {
            Cycles.add<system>(20_949_972_000);
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
        Cycles.add<system>(20_949_972_000);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
      };
      case(null) {
        let deployedCanisters = Buffer.Buffer<T.CanisterId>(50);
        for (cid in notificationsDirectory.keys()) {
          if (not(Buffer.contains<T.CanisterId>(deployedCanisters, cid, Principal.equal))) {
            deployedCanisters.append(Buffer.fromArray<T.CanisterId>([cid]));
          };
        };

        for(canister_id in deployedCanisters.vals()) {
          Cycles.add<system>(20_949_972_000);
          await IC_MANAGEMENT.ic.stop_canister({ canister_id });
        };
      };
    };
  };

  /// returns true if canister have storage memory,
  /// false if havent enough
  public func checkMemoryStatus(canister_id: T.CanisterId) : async Bool {
    switch(notificationsDirectory.get(canister_id)) {
      case(null) throw Error.reject("Cant find notifications canisters registered");
      case(?values) {
        let { memory_size } = await IC_MANAGEMENT.ic.canister_status({ canister_id });
        memory_size > T.LOW_MEMORY_LIMIT
      };
    };
  };

  /// autonomous function to create canister
  private func _createCanister<system>(): async T.CanisterId {
    Debug.print(debug_show ("before create_canister: " # Nat.toText(Cycles.balance())));

    Cycles.add<system>(300_000_000_000);
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

  /// add notification to [notificationsDirectory] collection
  public shared({ caller }) func addNotification(receiverToken: T.UserToken, triggerToken: ?T.UserToken, notification: T.NotificationInfo) : async() {
    _callValidation(caller);

    // add notification to receiver user
    let _ = await HttpService.post(HT.apiUrl # "users/add-notification", {
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({ token = receiverToken; notification = notification.id }), ["token", "notification"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });

    switch(triggerToken) {
      case(null) {};
      case(?token) {
        // add notification to trigger user
        let _ = await HttpService.post(HT.apiUrl # "users/add-notification", {
          headers = [];
          bodyJson = switch(Serde.JSON.toText(to_candid({ token; notification = notification.id }), ["token", "notification"], null)) {
            case(#err(error)) throw Error.reject("Cannot serialize data");
            case(#ok(value)) value;
          };
        });
      };
    };

    try {
      var selectedCanister: ?(T.CanisterId, [T.NotificationId]) = null;

      let entries = notificationsDirectory.entries();

      // recursive function to know if canisterId have memory
      func checkCanisters() : async ?(T.CanisterId, [T.NotificationId]) {
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

      // get canister
      let (cid, notifications) = switch (selectedCanister) {
        case (null) throw Error.reject("Notifications canister not found");
        case (?value) value;
      };

      // add notification
      let notificationId = await Notifications.canister(cid).addNotification(notification);
      let notificationsCopy = Buffer.fromArray<T.NotificationId>(notifications);

      notificationsCopy.add(notificationId);

      notificationsDirectory.put(cid, Buffer.toArray<T.NotificationId>(notificationsCopy));
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };


  /// mark general notifications status as seen
  public shared({ caller }) func updateGeneralNotifications(token: T.UserToken, notificationIds: [T.NotificationId]) : async() {
    _callValidation(caller);

    let notificationIdsJson = await HttpService.get(HT.apiUrl # "users/notifications/" # token, { headers = []; });

    let userNotificationIds: [T.NotificationId] = switch(Serde.JSON.fromText(notificationIdsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");
      case(#ok(blob)) {
        let notifications: ?[T.NotificationId] = from_candid(blob);
        switch(notifications) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?value) value;
        };
      };
    };

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      // filter user notifications to verify if providing own notifications
      let verifiedNotificationIds = Array.filter<T.NotificationId>(notificationIds, func (x) {
        Array.find<T.NotificationId>(userNotificationIds, func y = x == y) != null
      });

      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.NotificationId>(canisterNotifications, func (id) {
        Array.find<T.NotificationId>(verifiedNotificationIds, func x = x == id) != null;
      });


      if (filteredIds.size() > 0) {
        // update notifications on canister
        await Notifications.canister(cid).updateGeneral(filteredIds);
      }
    };
  };


  /// update event notification status
  public shared({ caller }) func updateEventNotification(token: T.UserToken, notificationId: T.NotificationId, eventStatus: T.NotificationEventStatus) : async() {
    _callValidation(caller);

    let queryParameter = "?id=" # notificationId;
    let jsonResponse = await HttpService.get(HT.apiUrl # "users/notification/" # token # queryParameter, { headers = []; });

    let exists: Bool = switch(Serde.JSON.fromText(jsonResponse, null)) {
      case(#err(_)) false;
      case(#ok(blob)) {
        let exists: ?Text = from_candid(blob);
        switch(exists) {
          case(null) false;
          case(?value) Text.contains(value, #text "true");
        };
      };
    };

    if (not exists) throw Error.reject("notification id provided not match with user notifications");

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      switch(Array.find<T.NotificationId>(canisterNotifications, func x = notificationId == x)) {
        case(null) throw Error.reject("notification id provided not found in records");
        case(?value) {
          // update notifications on canister
          return await Notifications.canister(cid).updateEvent(value, eventStatus);
        };
      };
    };
  };


  /// clear general notifications from [notificationsDirectory] collection
  public shared({ caller }) func clearGeneralNotifications(token: T.UserToken, notificationIds: [T.NotificationId]) : async() {
    _callValidation(caller);

    let notificationIdsJson = await HttpService.get(HT.apiUrl # "users/notifications/" # token, { headers = []; });

    let userNotificationIds: [T.NotificationId] = switch(Serde.JSON.fromText(notificationIdsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");
      case(#ok(blob)) {
        let notifications: ?[T.NotificationId] = from_candid(blob);
        switch(notifications) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?value) value;
        };
      };
    };

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      // filter user notifications to verify if providing own notifications
      let verifiedNotificationIds = Array.filter<T.NotificationId>(notificationIds, func (x) {
        Array.find<T.NotificationId>(userNotificationIds, func y = x == y) != null
      });

      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.NotificationId>(canisterNotifications, func (id) {
        Array.find<T.NotificationId>(verifiedNotificationIds, func x = x == id) != null;
      });


      if (filteredIds.size() > 0) {
        // clear notifications from records
        let _ = await HttpService.post(HT.apiUrl # "users/clear-notifications", {
            headers = [];
            bodyJson = switch(Serde.JSON.toText(to_candid({ token; notifications = filteredIds }), ["token", "notifications"], null)) {
              case(#err(error)) throw Error.reject("Cannot serialize data");
              case(#ok(value)) value;
            };
          });

        // clear notifications on canister
        await Notifications.canister(cid).clearNotifications(filteredIds);

        let notifications = Buffer.fromArray<T.NotificationId>(canisterNotifications);

        // clear notifications on directory
        for(notificationId in filteredIds.vals()) {
          let index = switch(Buffer.indexOf<T.NotificationId>(notificationId, notifications, Text.equal)) {
            case(null) throw Error.reject("Notification not found");
            case(?value) value;
          };
          let _ = notifications.remove(index);
        };

        notificationsDirectory.put(cid, Buffer.toArray<T.NotificationId>(notifications));
      }
    };
  };


  /// clear event notification from [notificationsDirectory] collection
  public shared({ caller }) func clearEventNotification(receiverToken: T.UserToken, triggerToken: ?T.UserToken, notificationId: T.NotificationId) : async() {
    _callValidation(caller);

    let queryParameter = "?id=" # notificationId;
    let jsonResponse = await HttpService.get(HT.apiUrl # "users/notification/" # receiverToken # queryParameter, { headers = []; });

    let receiverExists: Bool = switch(Serde.JSON.fromText(jsonResponse, null)) {
      case(#err(_)) false;
      case(#ok(blob)) {
        let exists: ?Text = from_candid(blob);
        switch(exists) {
          case(null) false;
          case(?value) Text.contains(value, #text "true");
        };
      };
    };

    let triggerExists: Bool = switch(triggerToken) {
      case(null) false;
      case(?token) {
        let jsonResponse = await HttpService.get(HT.apiUrl # "users/notification/" # token # queryParameter, { headers = []; });
        switch(Serde.JSON.fromText(jsonResponse, null)) {
          case(#err(_)) false;
          case(#ok(blob)) {
            let exists: ?Text = from_candid(blob);
            switch(exists) {
              case(null) false;
              case(?value) Text.contains(value, #text "true");
            };
          };
        };
      };
    };

    if (not receiverExists) throw Error.reject("notification id provided not match with user notifications");

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      switch(Array.find<T.NotificationId>(canisterNotifications, func x = notificationId == x)) {
        case(null) throw Error.reject("notification id provided not found in records");
        case(?id) {
          // clear notification from records
          let _ = await HttpService.post(HT.apiUrl # "users/clear-notifications", {
              headers = [];
              bodyJson = switch(Serde.JSON.toText(to_candid({ token = receiverToken; notifications = [id] }), ["token", "notifications"], null)) {
                case(#err(error)) throw Error.reject("Cannot serialize data");
                case(#ok(value)) value;
              };
            });

          // clear notification if all users has been cleaned
          if (not triggerExists) await Notifications.canister(cid).clearNotification(id);
          return;
        };
      };
    };
  };


  // get user notifications
  public shared({ caller }) func getNotifications(token: T.UserToken, page: ?Nat, length: ?Nat, notificationTypes: [T.NotificationType]): async [T.NotificationInfo] {
    _callValidation(caller);

    let pageParam = switch(page) {
      case(null) "1";
      case(?value) Nat.toText(value);
    };
    let lengthParam = switch(length) {
      case(null) "50";
      case(?value) Nat.toText(value);
    };

    let queryParameters = "?page=" # pageParam # "&length=" # lengthParam;
    let notificationIdsJson = await HttpService.get(HT.apiUrl # "users/notifications/" # token # queryParameters, { headers = []; });

    let notificationIds: [T.NotificationId] = switch(Serde.JSON.fromText(notificationIdsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize profile data");
      case(#ok(blob)) {
        let notifications: ?[T.NotificationId] = from_candid(blob);
        switch(notifications) {
          case(null) throw Error.reject("cannot serialize profile data");
          case(?value) value;
        };
      };
    };


    let notifications = Buffer.Buffer<T.NotificationInfo>(50);

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.NotificationId>(canisterNotifications, func (id) {
        Array.find<T.NotificationId>(notificationIds, func x = x == id) != null;
      });


      if (filteredIds.size() > 0) {
        let notificationsInfo = await Notifications.canister(cid).getNotifications(filteredIds);
        let notificationsInfoFiltered = Array.filter<T.NotificationInfo>(notificationsInfo, func (item) {
          notificationTypes.size() < 1 or Array.find<T.NotificationType>(notificationTypes, func x = item.notificationType == x) != null
        });

        // add notifications to buffer
        for(notification in notificationsInfoFiltered.vals()) {
          notifications.add(notification)
        };
      }
    };

    Buffer.toArray<T.NotificationInfo>(notifications);
  };
}
