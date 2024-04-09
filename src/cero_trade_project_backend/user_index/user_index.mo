import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";

// types
import T "../types";

actor UserIndex {
  let usersLocation: HM.HashMap<T.UID, T.CanisterId> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of usersLocation collection
  public query func length(): async Nat {
    usersLocation.size();
  };

  /// register [usersLocation] collection
  public func registerUser(uid: T.UID, cid: T.CanisterId) : async() {
    usersLocation.put(uid, cid);
  };

  /// get canister id that allow current user
  public query func getUserCanister(uid: T.UID) : async T.CanisterId {
    switch (usersLocation.get(uid)) {
      case (null) { throw Error.reject("User not found"); };
      case (?cid) { return cid; };
    };
  };
}
