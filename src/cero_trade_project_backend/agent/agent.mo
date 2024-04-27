import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Int "mo:base/Int";

// canisters
import HttpService "canister:http_service";
import UserIndex "canister:user_index";
import TokenIndex "canister:token_index";
import TransactionIndex "canister:transaction_index";
import Marketplace "canister:marketplace";

// types
import T "../types";
import HT "../http_service/http_service_types";
import ICRC "../ICRC";

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

    // mint token to user token collection
    let tokensInMarket = await Marketplace.getUserTokensOnSale(caller, tokenId);
    await TokenIndex.mintToken(caller, tokenId, amount, Float.fromInt(tokensInMarket));

    // update user portfolio
    await UserIndex.updatePorfolio(caller, tokenId);
  };


  /// helper function to performe burn method
  private func _burnToken(caller: T.UID, tokenId: T.TokenId, amount: Float): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // burn token to user token collection
    let tokensInMarket = await Marketplace.getUserTokensOnSale(caller, tokenId);
    await TokenIndex.burnToken(caller, tokenId, amount, Float.fromInt(tokensInMarket));

    // update user portfolio
    await UserIndex.updatePorfolio(caller, tokenId);
  };

  /// performe mint with tokenId and amount requested
  public shared({ caller }) func burnToken(tokenId: T.TokenId, amount: Float): async() { await _burnToken(caller, tokenId, amount) };


  /// get profile information
  public shared({ caller }) func getProfile(): async T.UserProfile { await UserIndex.getProfile(caller) };


  // TODO add here reddemption response
  /// get portfolio information
  public shared({ caller }) func getPortfolio(): async { tokensInfo: [T.TokenInfo]; tokensRedemption: [T.TransactionInfo] } {
    let tokenIds = await UserIndex.getPortfolioTokenIds(caller);
    let tokensInfo: [T.TokenInfo] = await TokenIndex.getPortfolio(caller, tokenIds);

    let txIds = await UserIndex.getTransactionIds(caller);
    let tokensRedemption: [T.TransactionInfo] = await TransactionIndex.getRedemptions(txIds);

    { tokensInfo; tokensRedemption };
  };


  /// get portfolio information
  public shared({ caller }) func getSinglePortfolio(tokenId: T.TokenId): async T.TokenInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    await TokenIndex.getTokenPortfolio(caller, tokenId);
  };


  /// performe token purchase
  public shared({ caller }) func purchaseToken(tokenId: T.TokenId, recipent: T.Beneficiary, tokenAmount: Float, price: T.Price): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let testingRecipent = caller /* recipent <- replace in future for recipent */;

    let recipentLedger = await UserIndex.getUserLedger(testingRecipent);

    // performe ICP transfer and update token canister
    let tokensInMarket = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let blockHash: T.BlockHash = await TokenIndex.purchaseToken(caller, { uid = testingRecipent; ledger = recipentLedger }, tokenId, tokenAmount, Float.fromInt(tokensInMarket));

    // build transaction
    let priceICP: ICRC.Tokens = { e8s = Nat64.fromNat(price) };

    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      blockHash;
      from = caller;
      to = #transferRecipent(testingRecipent);
      tokenId;
      txType = #transfer("transfer");
      tokenAmount;
      priceICP;
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    // take token off marketplace
    await Marketplace.takeOffSale(tokenId, Int.abs(Float.toInt(tokenAmount)), caller);

    txInfo
  };


  /// ask market to put on sale token
  public shared({ caller }) func sellToken(tokenId: T.TokenId, quantity: T.TokenIdQuantity, price: T.Price, currency: T.Currency): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);


    // check if user is already selling
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);

    let availableTokens = tokenPortofolio.totalAmount - Float.fromInt(tokensInSale);

    // check if user has enough tokens
    if (availableTokens < Float.fromInt(quantity)) throw Error.reject("Not enough tokens");

    await Marketplace.putOnSale(tokenId, quantity, caller, price, currency);
  };


  // ask market to take off market
  public shared ({ caller }) func takeTokenOffMarket(tokenId: T.TokenId, quantity: T.TokenIdQuantity): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

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


  // redeem certificate by burning user tokens
  public shared({ caller }) func redeemToken(tokenId: T.TokenId, beneficiary: T.Beneficiary, quantity: T.TokenIdQuantity): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);

    // check if user has enough tokens
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let availableTokens = tokenPortofolio.totalAmount - Float.fromInt(tokensInSale);

    if (availableTokens < Float.fromInt(quantity)) throw Error.reject("Not enough tokens");

    // ask token to burn the tokens
    await _burnToken(caller, tokenId, Float.fromInt(quantity));

    // build transaction
    let priceICP: ICRC.Tokens = { e8s = 10_000 };

    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      blockHash = 12345678901234567890;
      from = caller;
      to = #redemptionRecipent(beneficiary);
      tokenId;
      txType = #redemption("redemption");
      tokenAmount = Float.fromInt(quantity);
      priceICP;
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    txInfo
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
