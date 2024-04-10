import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Serde "mo:serde";
import Debug "mo:base/Debug";

// canisters
import HttpService "canister:http_service";
import Users "canister:users";

// types
import T "../types";
import HT "../http_service/http_service_types";

actor UserIndex {
  stable let notExists = "User doesn't exists on cero trade";

  let usersLocation: HM.HashMap<T.UID, T.CanisterId> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of usersLocation collection
  public query func length(): async Nat { usersLocation.size() };

  /// validate user existence (privated)
  private func _checkPrincipal(uid: T.UID) : Bool { usersLocation.get(uid) != null };

  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool { usersLocation.get(uid) != null };

  /// register [usersLocation] collection
  public func registerUser(uid: T.UID, token: Text) : async() {
    // TODO evaluate how to search specific canister to call registerUser func
    // register user
    let cid = await Users.registerUser(uid, token);

    usersLocation.put(uid, cid);
  };

  /// store user avatar into users collection
  public func storeCompanyLogo(uid: T.UID, avatar: [Nat8]): async() {
    let exists: Bool = _checkPrincipal(uid);
    if (not exists) throw Error.reject(notExists);

    try {
      // TODO evaluate how to search specific canister to call storeCompanyLogo func
      await Users.storeCompanyLogo(uid, avatar);
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };

  /// delete user to cero trade
  public func deleteUser(uid: T.UID): async() {
    // TODO evaluate how to search specific canister to call getUserToken func
    let token = await Users.getUserToken(uid);

    let formData = { token };
    let formBlob = to_candid(formData);
    let formKeys = ["token"];

    let res = await HttpService.post(HT.apiUrl # "users/delete", {
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });

    let removedUser = usersLocation.remove(uid);

    // TODO evaluate how to search specific canister to call deleteUser func
    await Users.deleteUser(uid);
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

    // TODO evaluate how to search specific canister to call updatePorfolio func
    await Users.updatePorfolio(uid, token)
  };


  /// get profile information
  public func getProfile(uid: T.UID): async T.UserProfile {
    let exists: Bool = _checkPrincipal(uid);
    if (not exists) throw Error.reject(notExists);

    // TODO fetch other profile data from web2 data base
    // let token = await Users.getUserToken(uid);
    // let res = await HttpService.get(HT.apiUrl # "users/retrieve?token=" # token, { headers = [] });
    // Debug.print(debug_show(res));

    // TODO evaluate how to search specific canister to call getCompanyLogo func
    let companyLogo = await Users.getCompanyLogo(uid);
    { companyLogo }
  };


  /// get portfolio information
  public func getPortfolio(uid: T.UID): async [T.TokenInfo] {
    let exists: Bool = _checkPrincipal(uid);
    if (not exists) throw Error.reject(notExists);

    // TODO evaluate how to search specific canister to call getPortfolio func
    await Users.getPortfolio(uid);
  };
}
