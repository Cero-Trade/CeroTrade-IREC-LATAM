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

  // redeem certificate by burning user tokens
  public shared({ caller }) func redeem(tokenId: T.TokenId, beneficiary: T.CompanyName, quantity: T.TokenIdQuantity): async() {
    // check if user exists
    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);

    // check if user has enough tokens
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let availableTokens =  tokenPortofolio.totalAmount - Float.fromInt(tokensInSale);

    if (availableTokens < Float.fromInt(quantity)) throw Error.reject("Not enough tokens");

    // ask token to burn the tokens
    await TokenIndex.burnToken(caller, tokenId, Float.fromInt(quantity));

    // add transaction
    
    // get last transaction id

    let lastTransactionId = await TransactionIndex.length();
    transactionId := Nat.toText(lastTransactionId + 1);

    let transactionType = #redemption("redeem");
    let transactionInfo = {
      tokenId: tokenId;
      recipient: beneficiary;
      quantity: quantity;
      txType: transactionType;
    }
    // add transaction
    await TransactionIndex.registerTransaction(transactionId, transactionInfo);
    // add user transaction
    await UserIndex.updateTransactions(caller, transactionId);

    return ();
  };

  // convert Text to Nat
  public func textToNat( txt : Text) : async Nat {
    assert(txt.size() > 0);
    let chars = txt.chars();

    var num : Nat = 0;
    for (v in chars){
      let charToNum = Nat32.toNat(Char.toNat32(v)-48);
      assert(charToNum >= 0 and charToNum <= 9);
      num := num * 10 +  charToNum;          
    };

    num;
  };

}
