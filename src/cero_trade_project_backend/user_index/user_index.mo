import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";

// canisters
import Users "canister:users";

// types
import T "../types";

actor UserIndex {
  stable let notExists = "User doesn't exists on cero trade";

  let usersLocation: HM.HashMap<T.UID, T.CanisterId> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of usersLocation collection
  public query func length(): async Nat { usersLocation.size() };

  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool { usersLocation.get(uid) != null };

  /// register [usersLocation] collection
  public func registerUser(uid: T.UID, token: Text) : async() {
    // TODO evaluate how to search specific canister to call mintToken func
    // register user
    let cid = await Users.registerUser(uid, token);

    usersLocation.put(uid, cid);
  };

  /// store user avatar into users collection
  public func storeCompanyLogo(uid: T.UID, avatar: [Nat8]): async() {
    let exists: Bool = await checkPrincipal(uid);
    if (not exists) throw Error.reject(notExists);

    try {
      // TODO evaluate how to search specific canister to call mintToken func
      await Users.storeCompanyLogo(uid, avatar);
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };

  /// get canister id that allow current user
  public query func getUserCanister(uid: T.UID) : async T.CanisterId {
    switch (usersLocation.get(uid)) {
      case (null) { throw Error.reject("User not found"); };
      case (?cid) { return cid; };
    };
  };

  /// update user portfolio
  public func updatePorfolio(uid: T.UID, token: T.TokenInfo) : async() {
    if (usersLocation.get(uid) == null) throw Error.reject("User doesn't exists");

    // TODO evaluate how to search specific canister to call mintToken func
    await Users.updatePorfolio(uid, token)
  };
}
