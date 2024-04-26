import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Float "mo:base/Float";

// canisters
import HttpService "canister:http_service";
import UserIndex "canister:user_index";
import TokenIndex "canister:token_index";
import TransactionIndex "canister:token_index";
import Marketplace "canister:marketplace";

// types
import T "../types";
import HT "../http_service/http_service_types";

actor Agent {
  // constants
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
      case(#users("users")) await UserIndex.registerWasmArray(caller, array);
      case(#transactions("transactions")) await TransactionIndex.registerWasmArray(caller, array);
      case(#token("token")) await TokenIndex.registerWasmArray(caller, array);
      case _ throw Error.reject("Invalid input");
    };
  };

  /// performe mint with tokenId and amount requested
  public shared({ caller }) func mintToken(tokenId: T.TokenId, amount: Float): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    await TokenIndex.mintToken(caller, tokenId, amount);

    await UserIndex.updatePorfolio(caller, tokenId);
  };

  /// performe mint with tokenId and amount requested
  public shared({ caller }) func burnToken(tokenId: T.TokenId, amount: Float): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

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

  // TODO add here reddemption response
  /// get portfolio information
  public shared({ caller }) func getSinglePortfolio(tokenId: T.TokenId): async T.TokenInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    await TokenIndex.getTokenPortfolio(caller, tokenId);
  };

  /// get left to mint about token
  public shared({ caller }) func getRemainingToken(tokenId: T.TokenId): async Float {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    await TokenIndex.getRemainingAmount(tokenId);
  };


  /// performe token purchase
  public shared({ caller }) func purchaseToken(tokenId: T.TokenId, recipent: T.UID, amount: Float): async Nat64 {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let recipentLedger = await UserIndex.getUserLedger(recipent);

    // performe ICP transfer and update token canister
    await TokenIndex.purchaseToken(caller, { uid = recipent; ledger = recipentLedger }, tokenId, amount);

    // TODO checkpout about update marketplace canister here ---> call takeOffMarket()
  };


  // peforme redeemption about token
  public shared({ caller }) func redeemToken(tokenId: T.TokenId, amount: Float, beneficiary: T.UID): async() {
    // TODO call token_index to burn token --> validate selected amount (checkout amount out market, need to rest amount in market with out market to know if can redeem)

    // TODO save transaction
  };


  /// ask market to put on sale token
  public shared({ caller }) func sellToken(tokenId: T.TokenId, quantity: T.TokenIdQuantity): async() {
    // check if user exists
    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);


    // check if user is already selling
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);

    let availableTokens = tokenPortofolio.totalAmount - Float.fromInt(tokensInSale);

    // check if user has enough tokens
    if (availableTokens < Float.fromInt(quantity)) throw Error.reject("Not enough tokens");

    await Marketplace.putOnSale(tokenId, quantity, caller);

    return ();
  };

  // ask market to take off market
  public shared ({ caller }) func takeTokenOffMarket(tokenId: T.TokenId, quantity: T.TokenIdQuantity): async() {
    // check if user exists
    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);

    // check if user is already selling
    let isSelling = await Marketplace.isSellingToken(caller, tokenId);
    if (isSelling == false) throw Error.reject("User is not selling this token");

    // check if user has enough tokens
    let tokenInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    if (Float.fromInt(tokenInSale) < Float.fromInt(quantity)) throw Error.reject("Not enough tokens");

    await Marketplace.takeOffSale(tokenId, quantity, caller);

    return ();
  };

}
