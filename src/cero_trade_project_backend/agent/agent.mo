import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";

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


  /// login user into cero trade
  public shared({ caller }) func login(): async() {
    // WARN just for debug
    Debug.print(Principal.toText(caller));

    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);
  };


  /// register user into cero trade
  public shared({ caller }) func register(form: T.RegisterForm): async() { await UserIndex.registerUser(caller, form) };


  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(avatar: T.CompanyLogo): async() { await UserIndex.storeCompanyLogo(caller, avatar) };


  /// delete user into cero trade
  public shared({ caller }) func deleteUser(): async() { await UserIndex.deleteUser(caller) };


  /// register Token Wasm Module from client
  public shared({ caller }) func registerTokenWasmModule(moduleName: T.WasmModuleName, array: [Nat]): async [Nat] {
    switch(moduleName) {
      case(#users("users")) [];
      case(#token("token")) await TokenIndex.registerWasmArray(caller, array);
      case _ throw Error.reject("Invalid input");
    };
  };


  /// performe mint with tokenId and amount requested
  public shared({ caller }) func mintToken(tokenId: T.TokenId, amount: Float): async() {
    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);

    await TokenIndex.mintToken(caller, tokenId, amount);

    await UserIndex.updatePorfolio(caller, tokenId);
  };


  /// performe mint with tokenId and amount requested
  public shared({ caller }) func burnToken(tokenId: T.TokenId, amount: Float): async() {
    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);

    await TokenIndex.burnToken(caller, tokenId, amount);

    await UserIndex.updatePorfolio(caller, tokenId);
  };


  /// get profile information
  public shared({ caller }) func getProfile(): async T.UserProfile { await UserIndex.getProfile(caller) };


  /// get portfolio information
  public shared({ caller }) func getPortfolio(): async [T.TokenInfo] {
    let tokenIds = await UserIndex.getPortfolioTokenIds(caller);
    await TokenIndex.getPortfolio(caller, tokenIds);
  };
}
