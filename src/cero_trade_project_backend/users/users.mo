import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import AccountIdentifier "mo:account-identifier";

// types
import T "../types";

actor class Users() = this {
  stable let userNotFound: Text = "User not found";

  let users: HM.HashMap<T.UID, T.UserInfo> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of users collection
  public query func length(): async Nat {
    users.size();
  };

  /// register user to cero trade
  public func registerUser(uid: T.UID, token: Text): async T.CanisterID {
    let userLedger = AccountIdentifier.accountIdentifier(uid, AccountIdentifier.defaultSubaccount());
    let userInfo = await T.createUserInfo(uid, token, userLedger);

    users.put(uid, userInfo);

    Principal.fromActor(this)
  };
  
  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool {
    users.get(uid) != null
  };

  /// get user from users collection
  public query func getUserInfo(uid: T.UID) : async T.UserInfo {
    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info; };
    };
  };

  /// get vaultToken from user
  public query func getUserToken(uid: T.UID) : async Text {
    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken; };
    };
  };

  /// validate current token
  public query func validateToken(uid: T.UID, token: Text): async Bool {
    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken == token; };
    };
  };
}
