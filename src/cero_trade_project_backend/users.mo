import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Error "mo:base/Error";

// types
import T "./types";

actor class Users() = this {
  let users: HM.HashMap<T.UID, T.UserInfo> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// register user to cero trade
  public func registerUser(uid: T.UID, token: Text): async T.CanisterID {
    let userInfo = T.createUserInfo(uid, token, users.size()+1);

    users.put(uid, userInfo);

    Principal.fromActor(this)
  };

  /// get user from users collection
  public query func getUserInfo(uid: T.UID) : async T.UserInfo {
    switch (users.get(uid)) {
      case (null) { throw Error.reject("User not found"); };
      case (?info) { return info; };
    };
  };

  /// get vaultToken from user
  public query func getUserToken(uid: T.UID) : async Text {
    switch (users.get(uid)) {
      case (null) { throw Error.reject("User not found"); };
      case (?info) { return info.vaultToken; };
    };
  };

  // TODO define what should do this
  public func checkPrincipal(uid: T.UID) : async T.UserInfo {
    return {
      userID = 1;
      vaultToken = "Text";
      principal = Principal.fromText("asdasd-asdasd");
      redemptions = [];
      portfolio = [];
      transactions = [];
    }
  }
}
