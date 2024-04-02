import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Text "mo:base/Text";

// canisters
import HttpService "canister:http_service";
import UserIndex "canister:user_index";
import Users "canister:users";

// types
import T "../types";
import HT "../http_service/http_service_types";

actor Agent {

  /// register user into cero trade
  public shared(msg) func register(formInfo: Text): async() {
    // WARN just for debug
    Debug.print(Principal.toText(msg.caller));
    Debug.print(formInfo);

    let uid = msg.caller;

    let exists: Bool = await Users.checkPrincipal(uid);
    if (exists) throw Error.reject("User already exists on cero trade");

    try {
      // tokenize userInfo in web2 backend
      let token = await HttpService.post(HT.apiUrl # "api/user/store", {
          headers = [];
          bodyJson = "{\"principal\":\"" # Principal.toText(uid) # "\",\"userInfo\":\"" # formInfo # "\"}"
        });
      Debug.print(token);

      // register user
      let cid = await Users.registerUser(uid, token);

      // register user index
      await UserIndex.registerUser(uid, cid);
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };


  /// login user into cero trade
  public shared(msg) func login(): async() {
    // WARN just for debug
    Debug.print(Principal.toText(msg.caller));

    let exists: Bool = await Users.checkPrincipal(msg.caller);
    if (not exists) throw Error.reject("User doesn't exists on cero trade");
  }
}
