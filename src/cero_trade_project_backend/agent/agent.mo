import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";
import Int64 "mo:base/Int64";

// canisters
import HttpService "canister:http_service";
import UserIndex "canister:user_index";
import TokenIndex "canister:token_index";
import TransactionIndex "canister:transaction_index";
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
  public shared({ caller }) func mintToken(tokenId: T.TokenId, tokenAmount: T.TokenAmount): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // mint token to user token collection
    let tokensInMarket = await Marketplace.getUserTokensOnSale(caller, tokenId);
    await TokenIndex.mintToken(caller, tokenId, tokenAmount, tokensInMarket);

    // update user portfolio
    await UserIndex.updatePorfolio(caller, tokenId);
  };


  /// helper function to performe burn method
  private func _burnToken(caller: T.UID, tokenId: T.TokenId, tokenAmount: T.TokenAmount): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // burn token to user token collection
    let tokensInMarket = await Marketplace.getUserTokensOnSale(caller, tokenId);
    await TokenIndex.burnToken(caller, tokenId, tokenAmount, tokensInMarket);

    // update user portfolio
    await UserIndex.updatePorfolio(caller, tokenId);
  };

  /// performe mint with tokenId and amount requested
  public shared({ caller }) func burnToken(tokenId: T.TokenId, tokenAmount: T.TokenAmount): async() { await _burnToken(caller, tokenId, tokenAmount) };


  /// get profile information
  public shared({ caller }) func getProfile(): async T.UserProfile { await UserIndex.getProfile(caller) };


  /// function to know if user have current token
  public shared({ caller }) func checkUserToken(tokenId: T.TokenId): async Bool { await TokenIndex.checkUserToken(caller, tokenId) };

  /// get user portfolio information
  public shared({ caller }) func getPortfolio(): async { tokensInfo: [T.TokenInfo]; tokensRedemption: [T.TransactionInfo] } {
    let tokenIds = await UserIndex.getPortfolioTokenIds(caller);
    let tokensInfo: [T.TokenInfo] = await TokenIndex.getPortfolio(caller, tokenIds);

    let txIds = await UserIndex.getTransactionIds(caller);
    let tokensRedemption: [T.TransactionInfo] = await TransactionIndex.getRedemptions(txIds);

    { tokensInfo; tokensRedemption };
  };


  /// get user single portfolio information
  public shared({ caller }) func getSinglePortfolio(tokenId: T.TokenId): async T.TokenInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let tokenInfo: T.TokenInfo = await TokenIndex.getTokenPortfolio(caller, tokenId);
    let inMarket = await Marketplace.getAvailableTokens(tokenId);

    { tokenInfo with inMarket }
  };


  // TODO implements this function

  /// get token information
  public shared({ caller }) func getTokenDetails(tokenId: T.TokenId): async T.TokenInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let tokenInfo: T.TokenInfo = await TokenIndex.getTokenPortfolio(caller, tokenId);
    let inMarket = await Marketplace.getAvailableTokens(tokenId);

    { tokenInfo with inMarket }
  };


  /// get marketplace information
  public shared({ caller }) func getMarketplace(): async [T.MarketplaceInfo] {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let marketInfo: [{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceICP: T.Price;
      higherPriceICP: T.Price;
    }] = await Marketplace.getMarketplace();

    let tokensInfo: [T.AssetInfo] = await TokenIndex.getTokensInfo(Array.map<{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceICP: T.Price;
      higherPriceICP: T.Price;
    }, Text>(marketInfo, func x = x.tokenId));


    // map market and asset values to marketplace info
    let marketplace: [T.MarketplaceInfo] = Array.map<{ tokenId: T.TokenId; mwh: T.TokenAmount; lowerPriceICP: T.Price; higherPriceICP: T.Price; }, T.MarketplaceInfo>(marketInfo, func (item) {
      let assetInfo = Array.find<T.AssetInfo>(tokensInfo, func (info) { info.tokenId == item.tokenId });

      switch (assetInfo) {
        /// this case will not occur, just here to can compile
        case (null) {
          {
            tokenId = item.tokenId;
            mwh = item.mwh;
            lowerPriceICP = item.lowerPriceICP;
            higherPriceICP = item.higherPriceICP;
            assetInfo = {
              tokenId = item.tokenId;
              assetType = #hydro("hydro");
              startDate: Nat64 = 1714419814052;
              endDate: Nat64 = 1717012111263;
              co2Emission: Float = 11.22;
              radioactivityEmnission: Float = 10.20;
              volumeProduced: T.TokenAmount = 1000;
              deviceDetails = {
                name = "machine";
                deviceType = "type";
                group = #hydro("hydro");
                description = "description";
              };
              specifications = {
                deviceCode = "200";
                capacity: T.TokenAmount = 1000;
                location = "location";
                latitude: Float = 0;
                longitude: Float = 1;
                address = "address anywhere";
                stateProvince = "chile";
                country = "chile";
              };
              dates: [Nat64] = [1714419814052, 1717012111263, 1717012111263];
            };
          }
        };

        case (?asset) {
          // build MarketplaceInfo object
          {
            tokenId = item.tokenId;
            mwh = item.mwh;
            lowerPriceICP = item.lowerPriceICP;
            higherPriceICP = item.higherPriceICP;
            assetInfo = asset;
          }
        };
      };
    });

    marketplace
  };


  /// performe token purchase
  public shared({ caller }) func purchaseToken(tokenId: T.TokenId, recipent: T.Beneficiary, tokenAmount: T.TokenAmount, priceICP: Float): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let testingRecipent = caller /* recipent <- replace in future for recipent */;

    let recipentLedger = await UserIndex.getUserLedger(testingRecipent);

    // performe ICP transfer and update token canister
    let tokensInMarket = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let blockHash: T.BlockHash = await TokenIndex.purchaseToken(caller, { uid = testingRecipent; ledger = recipentLedger }, tokenId, tokenAmount, tokensInMarket);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      blockHash;
      from = caller;
      to = #transferRecipent(testingRecipent);
      tokenId;
      txType = #transfer("transfer");
      tokenAmount;
      priceICP = { e8s = Int64.toNat64(Float.toInt64(priceICP)) };
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    // take token off marketplace
    await Marketplace.takeOffSale(tokenId, tokenAmount, caller);

    txInfo
  };


  /// ask market to put on sale token
  public shared({ caller }) func sellToken(tokenId: T.TokenId, quantity: T.TokenAmount, priceICP: Float): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);


    // check if user is already selling
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let availableTokens: T.TokenAmount = tokenPortofolio.totalAmount - tokensInSale;

    // check if user has enough tokens
    if (availableTokens < quantity) throw Error.reject("Not enough tokens");

    await Marketplace.putOnSale(tokenId, quantity, caller, { e8s = Int64.toNat64(Float.toInt64(priceICP)) });
  };


  // ask market to take off market
  public shared ({ caller }) func takeTokenOffMarket(tokenId: T.TokenId, quantity: T.TokenAmount): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);

    // check if user is already selling
    let isSelling = await Marketplace.isSellingToken(caller, tokenId);
    if (isSelling == false) throw Error.reject("User is not selling this token");

    // check if user has enough tokens
    let tokenInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    if (tokenInSale < quantity) throw Error.reject("Not enough tokens");

    await Marketplace.takeOffSale(tokenId, quantity, caller);

    return ();
  };


  // redeem certificate by burning user tokens
  public shared({ caller }) func redeemToken(tokenId: T.TokenId, beneficiary: T.Beneficiary, quantity: T.TokenAmount): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);

    // check if user has enough tokens
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let availableTokens: T.TokenAmount = tokenPortofolio.totalAmount - tokensInSale;

    if (availableTokens < quantity) throw Error.reject("Not enough tokens");

    // ask token to burn the tokens
    await _burnToken(caller, tokenId, quantity);

    // build transaction
    let priceICP: T.Price = { e8s = 10_000 };

    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      blockHash = 12345678901234567890;
      from = caller;
      to = #redemptionRecipent(beneficiary);
      tokenId;
      txType = #redemption("redemption");
      tokenAmount = quantity;
      priceICP;
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    txInfo
  };
}
