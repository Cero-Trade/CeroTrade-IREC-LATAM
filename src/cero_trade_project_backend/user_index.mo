import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";

// types
import T "./types";

actor UserIndex {
  let userDict: HM.HashMap<T.UID, T.CanisterID> = HM.HashMap(16, Principal.equal, Principal.hash);

  
  /// get size of userDict collection
  public query func length(): async Nat {
    userDict.size();
  };

  /// register [userDict] collection
  public func registerUser(uid: T.UID, cid: T.CanisterID) : async() {
    userDict.put(uid, cid);
  };

  /// get canister id that allow current user
  public query func getUserCanister(uid: T.UID) : async T.CanisterID {
    switch (userDict.get(uid)) {
      case (null) { throw Error.reject("User not found"); };
      case (?cid) { return cid; };
    };
  };
}
