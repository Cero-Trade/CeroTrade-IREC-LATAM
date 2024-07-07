import Principal "mo:base/Principal";

// types
import T "../types"

module NotificationsInterface {
  public func canister(cid: Principal): Notifications { actor (Principal.toText(cid)) };

  public type Notifications = actor {
    length: query () -> async Nat;
    getNotification: (T.NotificationId) -> async T.NotificationInfo;
    getNotifications: ([T.NotificationId]) -> async [T.NotificationInfo];
    addNotification: (notification: T.NotificationInfo) -> async T.NotificationId;
    updateGeneral: (notificationIds: [T.NotificationId]) -> async();
    updateEvent: (notificationId: T.NotificationId, eventStatus: T.NotificationEventStatus) -> async();
    clearNotifications: (notificationIds: [T.NotificationId]) -> async();
    clearNotification: (notificationId: T.NotificationId) -> async();
  };
}