import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";


// types
import T "../types";

shared({ caller = userIndexCaller }) actor class Users() {
  // constants
  stable let userNotFound: Text = "User not found";


  var users: HM.HashMap<T.UID, T.UserInfo> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var usersEntries : [(T.UID, T.UserInfo)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { usersEntries := Iter.toArray(users.entries()) };
  system func postupgrade() {
    users := HM.fromIter<T.UID, T.UserInfo>(usersEntries.vals(), 16, Principal.equal, Principal.hash);
    usersEntries := [];
  };

  private func _callValidation(caller: Principal) { assert userIndexCaller == caller };

  /// get size of users collection
  public query func length(): async Nat { users.size() };


  /// register user to Cero Trade
  public shared({ caller }) func registerUser(uid: T.UID, token: Text): async() {
    _callValidation(caller);

    let userInfo = {
      vaultToken = token;
      principal = uid;
      companyLogo = null;
    };

    users.put(uid, userInfo);
  };


  /// delete user to Cero Trade
  public shared({ caller }) func deleteUser(uid: T.UID): async() {
    _callValidation(caller);
    let _ = users.remove(uid)
  };


  /// store user company logo to Cero Trade
  public shared({ caller }) func storeCompanyLogo(uid: T.UID, avatar: T.CompanyLogo): async() {
    _callValidation(caller);

    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) {
        { info with companyLogo = ?avatar }
      };
    };

    users.put(uid, userInfo);
  };


  /// get user from usersAvatar collection
  public shared({ caller }) func getCompanyLogo(uid: T.UID) : async T.CompanyLogo {
    _callValidation(caller);

    let companyLogo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info.companyLogo;
    };

    switch(companyLogo) {
      case(null) throw Error.reject("Logo not found");
      case(?value) value;
    }
  };

  /// get vaultToken from user
  public shared({ caller }) func getUserToken(uid: T.UID) : async T.UserToken {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken; };
    };
  };

  /// update token stored
  public shared({ caller }) func updateUserToken(uid: T.UID, token: Text): async() {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) {
        users.put(uid, { info with vaultToken = token })
      };
    };
  };
}
