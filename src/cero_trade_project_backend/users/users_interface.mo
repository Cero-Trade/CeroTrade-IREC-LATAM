import Principal "mo:base/Principal";

// types
import T "../types"

module UsersInterface {
  public func canister(cid: Principal): Users { actor (Principal.toText(cid)) };

  public type Users = actor {
    length: query () -> async Nat;
    registerUser: (uid: T.UID, token: Text) -> async();
    deleteUser: (uid: T.UID) -> async();
    storeCompanyLogo: (uid: T.UID, avatar: T.ArrayFile) -> async();
    getCompanyLogo: query (uid: T.UID) -> async T.ArrayFile;
    getUserToken: query (uid: T.UID) -> async T.UserToken;
    updateUserToken: (uid: T.UID, token: Text) -> async();
  };
}