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
import T "./types";
import HT "./http_service/http_service_types";

actor Agent {

  /// register user into cero trade
  public shared(msg) func register(formInfo: Text) : async Text {
    // TODO just for debug
    Debug.print(Principal.toText(msg.caller));
    Debug.print(formInfo);

    let uid = msg.caller;

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

      "You have registered successfuly";
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  }
}
