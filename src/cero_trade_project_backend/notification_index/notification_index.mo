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
import Notifications "../notifications/notifications_interface";
import IC_MANAGEMENT "../ic_management_canister_interface";
import HTTP "../http_service/http_service_interface";

// types
import T "../types";
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

    // register wasm
    wasm_module := await IC_MANAGEMENT.getWasmModule(#notifications("notifications"));

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
        Cycles.add<system>(T.cycles);
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
        for (cid in notificationsDirectory.keys()) {
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
    switch(notificationsDirectory.get(canister_id)) {
      case(null) throw Error.reject("Cant find notifications canisters registered");
      case(?values) {
        let { memory_size } = await IC_MANAGEMENT.ic.canister_status({ canister_id });
        memory_size > IC_MANAGEMENT.LOW_MEMORY_LIMIT
      };
    };
  };

  /// autonomous function to create canister
  private func _createCanister<system>(): async T.CanisterId {
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

  // ======================================================================================================== //

  /// add notification to [notificationsDirectory] collection
  public shared({ caller }) func addNotification(receiverToken: T.UserToken, triggerToken: ?T.UserToken, notification: T.NotificationInfo) : async() {
    _callValidation(caller);

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

      // add notification to receiver user
      let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "notifications/add";
        port = null;
        uid = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({ token = receiverToken; notification = notificationId }), ["token", "notification"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });

      switch(triggerToken) {
        case(null) {};
        case(?token) {
          // add notification to trigger user
          let _ = await HTTP.canister.post({
            url = HTTP.apiUrl # "notifications/add";
            port = null;
            uid = null;
            headers = [];
            bodyJson = switch(Serde.JSON.toText(to_candid({ token; notification = notificationId }), ["token", "notification"], null)) {
              case(#err(error)) throw Error.reject("Cannot serialize data");
              case(#ok(value)) value;
            };
          });
        };
      };

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

    let notificationIdsJson = await HTTP.canister.get({
      url = HTTP.apiUrl # "notifications/" # token;
      port = null;
      uid = null;
      headers = [];
    });

    let userNotificationIds: [T.NotificationId] = switch(Serde.JSON.fromText(notificationIdsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize notification data");
      case(#ok(blob)) {
        let notifications: ?{notifications: [T.NotificationId]} = from_candid(blob);
        switch(notifications) {
          case(null) throw Error.reject("cannot serialize notification data");
          case(?value) value.notifications;
        };
      };
    };

    // Convert userNotificationIds to a HashMap for faster lookup
    let notificationIdMap = HM.fromIter<T.NotificationId, Null>(Iter.fromArray(Array.map<T.NotificationId, (T.NotificationId, Null)>(userNotificationIds, func id = (id, null))), 16, Text.equal, Text.hash);

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      // filter user notifications to verify if providing own notifications
      let verifiedNotificationIds = Array.filter<T.NotificationId>(notificationIds, func x = notificationIdMap.get(x) != null);

      // Convert verifiedNotificationIds to a HashMap for faster lookup
      let verifiedNotificationIdMap = HM.fromIter<T.NotificationId, Null>(Iter.fromArray(Array.map<T.NotificationId, (T.NotificationId, Null)>(verifiedNotificationIds, func id = (id, null))), 16, Text.equal, Text.hash);

      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.NotificationId>(canisterNotifications, func id = verifiedNotificationIdMap.get(id) != null);


      if (filteredIds.size() > 0) {
        // update notifications on canister
        await Notifications.canister(cid).updateGeneral(filteredIds);
      }
    };
  };


  /// clear general notifications from [notificationsDirectory] collection
  public shared({ caller }) func clearGeneralNotifications(token: T.UserToken, notificationIds: [T.NotificationId]) : async() {
    _callValidation(caller);

    let notificationIdsJson = await HTTP.canister.get({
      url = HTTP.apiUrl # "notifications/" # token;
      port = null;
      uid = null;
      headers = [];
    });

    let userNotificationIds: [T.NotificationId] = switch(Serde.JSON.fromText(notificationIdsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize notification data");
      case(#ok(blob)) {
        let notifications: ?{notifications: [T.NotificationId]} = from_candid(blob);
        switch(notifications) {
          case(null) throw Error.reject("cannot serialize notification data");
          case(?value) value.notifications;
        };
      };
    };

    // Convert userNotificationIds to a HashMap for faster lookup
    let notificationIdMap = HM.fromIter<T.NotificationId, Null>(Iter.fromArray(Array.map<T.NotificationId, (T.NotificationId, Null)>(userNotificationIds, func id = (id, null))), 16, Text.equal, Text.hash);

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      // filter user notifications to verify if providing own notifications
      let verifiedNotificationIds = Array.filter<T.NotificationId>(notificationIds, func x = notificationIdMap.get(x) != null);

      // Convert verifiedNotificationIds to a HashMap for faster lookup
      let verifiedNotificationIdMap = HM.fromIter<T.NotificationId, Null>(Iter.fromArray(Array.map<T.NotificationId, (T.NotificationId, Null)>(verifiedNotificationIds, func id = (id, null))), 16, Text.equal, Text.hash);

      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.NotificationId>(canisterNotifications, func id = verifiedNotificationIdMap.get(id) != null);


      if (filteredIds.size() > 0) {
        // clear notifications from records
        let _ = await HTTP.canister.post({
            url = HTTP.apiUrl # "notifications/clear";
            port = null;
            uid = null;
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


  /// update event notification from [notificationsDirectory] collection
  public shared({ caller }) func updateEventNotification(userCaller: T.UID, token: { receiver: T.UserToken; trigger: ?T.UserToken }, (cid: T.CanisterId, notification: T.NotificationInfo), eventStatus: ?T.NotificationEventStatus) : async Bool {
    _callValidation(caller);

    // get user and other user
    let userToken: T.UserToken = switch(userCaller == notification.receivedBy) {
      case(true) token.receiver;
      case(false) {
        switch(token.trigger) {
          case(null) throw Error.reject("triggeredBy not provided");
          case(?value) value;
        };
      }
    };

    let otherUserToken: T.UserToken = switch(userCaller == notification.receivedBy) {
      case(true) {
        switch(token.trigger) {
          case(null) throw Error.reject("triggeredBy not provided");
          case(?value) value;
        };
      };
      case(false) token.receiver;
    };

    let queryParameter = "?id=" # notification.id;

    // checkout user notification existance
    let jsonResponse = await HTTP.canister.get({
      url = HTTP.apiUrl # "notifications/check/" # userToken # queryParameter;
      port = null;
      uid = null;
      headers = [];
    });
    let userNotificationExists: Bool = Text.contains(jsonResponse, #text "true");
    if (not userNotificationExists) throw Error.reject("notification id provided not match with user notifications");

    // remove user notification register
    let _ = await HTTP.canister.post({
        url = HTTP.apiUrl # "notifications/clear";
        port = null;
        uid = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({ token = userToken; notifications = [notification.id] }), ["token", "notifications"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });

    // checkout other user notification existance
    let otherJsonResponse = await HTTP.canister.get({
      url = HTTP.apiUrl # "notifications/check/" # otherUserToken # queryParameter;
      port = null;
      uid = null;
      headers = [];
    });
    let otherUserNotificationExists = Text.contains(otherJsonResponse, #text "true");

    // variable to know which user has cancel
    var redemptionCancelled: Bool = false;

    // change event notification status
    switch(eventStatus) {
      case(null) {};
      case(?value) {
        // validate if current notification is type redemption and was cancelled to return tokens holded
        if (notification.notificationType == #redeem("redeem") and notification.eventStatus == ?#pending("pending") and value == #declined("declined")) {
          redemptionCancelled := true;
        };

        await Notifications.canister(cid).updateEvent(notification.id, value);
      };
    };

    // clear notification if all users has been cleaned
    if (not otherUserNotificationExists) await Notifications.canister(cid).clearNotification(notification.id);

    redemptionCancelled
  };

  // get user notification
  public shared({ caller }) func getNotification(notificationId: T.NotificationId): async (T.CanisterId, T.NotificationInfo) {
    _callValidation(caller);

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      switch(Array.find<T.NotificationId>(canisterNotifications, func id = id == notificationId)) {
        case(null) {};
        case(?value) {
          let notification = await Notifications.canister(cid).getNotification(value);

          return (cid, notification)
        };
      };
    };

    throw Error.reject("Notification not found");
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
    let notificationIdsJson = await HTTP.canister.get({
      url = HTTP.apiUrl # "notifications/" # token # queryParameters;
      port = null;
      uid = null;
      headers = [];
    });

    let notificationIds: [T.NotificationId] = switch(Serde.JSON.fromText(notificationIdsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize notification data");
      case(#ok(blob)) {
        let notifications: ?{notifications: [T.NotificationId]} = from_candid(blob);
        switch(notifications) {
          case(null) throw Error.reject("cannot serialize notification data");
          case(?value) value.notifications;
        };
      };
    };

    // Convert notificationIds to a HashMap for faster lookup
    let notificationIdMap = HM.fromIter<T.NotificationId, Null>(Iter.fromArray(Array.map<T.NotificationId, (T.NotificationId, Null)>(notificationIds, func id = (id, null))), 16, Text.equal, Text.hash);

    var notifications: [T.NotificationInfo] = [];

    // iterate notifications on directory
    for((cid, canisterNotifications) in notificationsDirectory.entries()) {
      // filter notification ids by present on current canister iterated
      let filteredIds = Array.filter<T.NotificationId>(canisterNotifications, func id = notificationIdMap.get(id) != null);

      if (filteredIds.size() > 0) {
        let notificationsInfo = await Notifications.canister(cid).getNotifications(filteredIds);

        let filteredNotificationsInfo = Array.filter<T.NotificationInfo>(notificationsInfo, func (item) {
          // filter notifications by NotificationType
          notificationTypes.size() < 1 or Array.find<T.NotificationType>(notificationTypes, func x = item.notificationType == x) != null
        });

        notifications := Array.flatten<T.NotificationInfo>([notifications, filteredNotificationsInfo]);
      }
    };

    notifications
  };
}
