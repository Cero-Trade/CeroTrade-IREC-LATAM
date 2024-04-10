import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Serde "mo:serde";

// canisters
import HttpService "canister:http_service";
import UserIndex "canister:user_index";
import TokenIndex "canister:token_index";

// types
import T "../types";
import HT "../http_service/http_service_types";

actor Agent {
  stable let alreadyExists = "User already exists on cero trade";
  stable let notExists = "User doesn't exists on cero trade";

  /// register user into cero trade
  public shared({ caller }) func register(form: T.RegisterForm): async() {
    // WARN just for debug
    Debug.print(Principal.toText(caller));

    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (exists) throw Error.reject(alreadyExists);

    try {
      let formData = {
        principalId = Principal.toText(caller);
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

      // WARN just for debug
      Debug.print("token: " # token);

      // register user index
      await UserIndex.registerUser(caller, trimmedToken);
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };


  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(avatar: [Nat8]): async() {
    try {
      await UserIndex.storeCompanyLogo(caller, avatar);
    } catch (error) {
      throw Error.reject(Error.message(error));
    };
  };


  /// login user into cero trade
  public shared({ caller }) func login(): async() {
    // WARN just for debug
    Debug.print(Principal.toText(caller));

    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);
  };


  /// performe mint with tokenId and amount requested
  public shared({ caller }) func mintToken(tokenId: T.TokenId, amount: Nat): async() {
    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);

    await TokenIndex.mintToken(caller, tokenId, amount);
  };
}
