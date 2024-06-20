import Principal "mo:base/Principal";

// types
import T "../types"

module NotificationsInterface {
  public func canister(cid: Principal): Notifications { actor (Principal.toText(cid)) };

  public type Notifications = actor {
    length: query () -> async Nat;
    getNotifications: ([T.NotificationId]) -> async [T.NotificationInfo];
    addNotification: (notification: T.NotificationInfo) -> async T.NotificationId;
    removeNotification: (notification: T.NotificationId) -> async();
    clearNotifications: (notificationIds: [T.NotificationId]) -> async();
  };
}