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
  stable let ic : T.IC = actor ("aaaaa-aa");
  // private func UsersCanister(cid: T.CanisterId): T.UsersInterface { actor (Principal.toText(cid)) };
  stable let alreadyExists = "User already exists on cero trade";
  stable let notExists = "User doesn't exists on cero trade";


  let usersDirectoy: HM.HashMap<T.UID, T.CanisterId> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of usersDirectoy collection
  public query func length(): async Nat { usersDirectoy.size() };


  /// validate user existence (privated)
  private func _checkPrincipal(uid: T.UID) : Bool { usersDirectoy.get(uid) != null };

  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool { usersDirectoy.get(uid) != null };


  private func deleteUserWeb2(token: Text): async() {
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
  };

  /// register [usersDirectoy] collection
  public func registerUser(uid: T.UID, form: T.RegisterForm) : async() {
    // WARN just for debug
    Debug.print(Principal.toText(uid));

    let exists: Bool = _checkPrincipal(uid);
    if (exists) throw Error.reject(alreadyExists);

    let formData = {
      principalId = Principal.toText(uid);
      companyId = form.companyId;
      companyName = form.companyName;
      country = form.country;
      city = form.city;
      address = form.address;
      email = form.email;
    };

    let formBlob = to_candid(formData);
    let formKeys = ["principalId", "companyId", "companyName", "country", "city", "address", "email"];

    // tokenize userInfo in web2 backend
    let token = await HttpService.post(HT.apiUrl # "users/store", {
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
    let trimmedToken = Text.trimEnd(Text.trimStart(token, #char '\"'), #char '\"');


    try {
      // WARN just for debug
      Debug.print("token: " # token);

      // TODO evaluate how to search specific canister to call registerUser func
      // register user
      let cid = await Users.registerUser(uid, trimmedToken);

      usersDirectoy.put(uid, cid);
    } catch (error) {
      await deleteUserWeb2(trimmedToken);

      throw Error.reject(Error.message(error));
    };
  };

  /// store user avatar into users collection
  public func storeCompanyLogo(uid: T.UID, avatar: T.CompanyLogo): async() {
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

    await deleteUserWeb2(token);

    let _ = usersDirectoy.remove(uid);

    // TODO evaluate how to search specific canister to call deleteUser func
    await Users.deleteUser(uid);
  };

  /// get canister id that allow current user
  public query func getUserCanister(uid: T.UID) : async T.CanisterId {
    switch (usersDirectoy.get(uid)) {
      case (null) { throw Error.reject("User not found"); };
      case (?cid) { return cid; };
    };
  };

  /// update user portfolio
  public func updatePorfolio(uid: T.UID, token: T.TokenId) : async() {
    if (usersDirectoy.get(uid) == null) throw Error.reject("User doesn't exists");

    // TODO evaluate how to search specific canister to call updatePorfolio func
    await Users.updatePorfolio(uid, token)
  };


  /// get profile information
  public func getProfile(uid: T.UID): async T.UserProfile {
    let exists: Bool = _checkPrincipal(uid);
    if (not exists) throw Error.reject(notExists);

    // TODO evaluate how to search specific canister to call getCompanyLogo func
    let token = await Users.getUserToken(uid);
    let profile = await HttpService.get(HT.apiUrl # "users/retrieve/" # token, { headers = [] });

    // TODO evaluate how to search specific canister to call getCompanyLogo func
    let companyLogo = await Users.getCompanyLogo(uid);

    { companyLogo; profile; }
  };


  /// get portfolio information
  public func getPortfolioTokenIds(uid: T.UID): async [T.TokenId] {
    let exists: Bool = _checkPrincipal(uid);
    if (not exists) throw Error.reject(notExists);

    // TODO evaluate how to search specific canister to call getPortfolioTokenIds func
    await Users.getPortfolioTokenIds(uid);
  };
}
