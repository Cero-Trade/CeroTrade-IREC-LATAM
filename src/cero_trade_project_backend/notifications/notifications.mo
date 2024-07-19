import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";
import Error "mo:base/Error";


// types
import T "../types";

shared({ caller = notificationIndexCaller }) actor class Notifications() {
  var notifications: HM.HashMap<T.NotificationId, T.NotificationInfo> = HM.HashMap(16, Text.equal, Text.hash);
  stable var notificationsEntries : [(T.NotificationId, T.NotificationInfo)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { notificationsEntries := Iter.toArray(notifications.entries()) };
  system func postupgrade() {
    notifications := HM.fromIter<T.NotificationId, T.NotificationInfo>(notificationsEntries.vals(), 16, Text.equal, Text.hash);
    notificationsEntries := [];
  };

  private func _callValidation(caller: Principal) { assert notificationIndexCaller == caller };

  /// get size of notifications collection
  public query func length(): async Nat { notifications.size() };

  private func generateNotificationId(): async Text {
    let g = Source.Source();
    UUID.toText(await g.new());
  };

  // get notifications on Cero Trade
  public shared({ caller }) func getNotification(notificationId: T.NotificationId): async T.NotificationInfo {
    _callValidation(caller);

    switch(notifications.get(notificationId)) {
      case(null) throw Error.reject("Notification not found");
      case(?value) value;
    };
  };

  // get notifications on Cero Trade
  public shared({ caller }) func getNotifications(notificationIds: [T.NotificationId]): async [T.NotificationInfo] {
    _callValidation(caller);

    let notificationsInfo = Buffer.Buffer<T.NotificationInfo>(50);

    for(notification in notificationIds.vals()) {
      switch(notifications.get(notification)) {
        case(null) {};
        case(?value) notificationsInfo.add(value);
      };
    };

    Buffer.toArray<T.NotificationInfo>(notificationsInfo);
  };

  /// add notification to Cero Trade
  public shared({ caller }) func addNotification(notification: T.NotificationInfo): async T.NotificationId {
    _callValidation(caller);

    let id = await generateNotificationId();
    let buildNotification = { notification with id };

    notifications.put(buildNotification.id, buildNotification);
    id
  };

  /// update general notification statuses
  public shared({ caller }) func updateGeneral(notificationIds: [T.NotificationId]): async() {
    _callValidation(caller);

    for(notificationId in notificationIds.vals()) {
      var notification = switch(notifications.get(notificationId)) {
        case(null) throw Error.reject("Notification not found");
        case(?value) value;
      };

      if (notification.notificationType == #general("general")) {
        notification := { notification with status = ?#seen("seen") };
      };

      notifications.put(notificationId, notification);
    };
  };

  /// update event notification statuses
  public shared({ caller }) func updateEvent(notificationId: T.NotificationId, eventStatus: T.NotificationEventStatus): async() {
    _callValidation(caller);

    var notification = switch(notifications.get(notificationId)) {
      case(null) throw Error.reject("Notification not found");
      case(?value) value;
    };

    if (notification.notificationType != #general("general")) {
      notification := { notification with eventStatus = ?eventStatus };
    };

    notifications.put(notificationId, notification);
  };

  /// clear notifications from Cero Trade
  public shared({ caller }) func clearNotifications(notificationIds: [T.NotificationId]): async() {
    _callValidation(caller);

    for(notification in notificationIds.vals()) {
      let _ = notifications.remove(notification);
    };
  };

  /// clear notification from Cero Trade
  public shared({ caller }) func clearNotification(notificationId: T.NotificationId): async() {
    _callValidation(caller);

    let _ = notifications.remove(notificationId);
  };
}
