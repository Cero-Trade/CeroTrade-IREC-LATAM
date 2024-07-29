import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";
import Int64 "mo:base/Int64";
import Buffer "mo:base/Buffer";
import DateTime "mo:datetime/DateTime";

// canisters
import UserIndex "canister:user_index";
import TokenIndex "canister:token_index";
import TransactionIndex "canister:transaction_index";
import Marketplace "canister:marketplace";
import Statistics "canister:statistics";
import NotificationIndex "canister:notification_index";

// interfaces
import IC_MANAGEMENT "../ic_management_canister_interface";

// types
import T "../types";

actor class Agent() = this {
  stable var controllers: ?[Principal] = null;

  // constants
  stable let notExists = "User doesn't exists on Cero Trade";


  /// login user into Cero Trade
  public shared({ caller }) func login(): async() {
    // WARN just for debug
    Debug.print(Principal.toText(caller));

    let exists: Bool = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);
  };


  /// register user into Cero Trade
  public shared({ caller }) func register(form: T.RegisterForm, beneficiary: ?T.BID): async() {
    await UserIndex.registerUser(caller, form, beneficiary)
  };


  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(avatar: T.CompanyLogo): async() { await UserIndex.storeCompanyLogo(caller, avatar) };


  /// delete user into Cero Trade
  public shared({ caller }) func deleteUser(): async() { await UserIndex.deleteUser(caller) };

  /// get canister controllers
  public shared({ caller }) func getControllers(): async ?[Principal] {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    await IC_MANAGEMENT.getControllers(Principal.fromActor(this));
  };

  /// register canister controllers
  public shared({ caller }) func registerControllers(): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    controllers := await IC_MANAGEMENT.getControllers(Principal.fromActor(this));

    await UserIndex.registerControllers();
    await TokenIndex.registerControllers();
    await TransactionIndex.registerControllers();
    await NotificationIndex.registerControllers();
  };

  /// register a canister wasm module
  public shared({ caller }) func registerWasmModule(moduleName: T.WasmModuleName): async() {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(moduleName) {
      case(#token("token")) await TokenIndex.registerWasmArray();
      case(#users("users")) await UserIndex.registerWasmArray();
      case(#transactions("transactions")) await TransactionIndex.registerWasmArray();
      case(#notifications("notifications")) await NotificationIndex.registerWasmArray();
      case _ throw Error.reject("Module name doesn't exists");
    };
  };


  // /// register token on platform
  // public shared({ caller }) func registerToken(tokenId: Text, name: Text, symbol: Text, logo: Text): async (T.CanisterId, T.AssetInfo) {
  //   IC_MANAGEMENT.adminValidation(caller, controllers);
  //   let tokenStats = await TokenIndex.registerToken(tokenId, name, symbol, logo);
  //   tokenStats
  // };


  /// import user tokens
  public shared({ caller }) func importUserTokens(): async [{ mwh: T.TokenAmount; assetInfo: T.AssetInfo }] {
    let userToken = await UserIndex.getUserToken(caller);
    await TokenIndex.importUserTokens(userToken);
  };


  /// performe mint with tokenId and amount requested
  public shared({ caller }) func mintTokenToUser(recipent: T.BID, tokenId: T.TokenId, tokenAmount: T.TokenAmount): async T.TxIndex {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    // check if user exists
    if (not (await UserIndex.checkPrincipal(recipent))) throw Error.reject(notExists);

    // mint token to user token collection
    let txIndex = await TokenIndex.mintTokenToUser(recipent, tokenId, tokenAmount);

    // update user portfolio
    await UserIndex.updatePortfolio(recipent, tokenId, { delete = false });

    // register asset statistic
    await Statistics.registerAssetStatistic(tokenId, { mwh = ?tokenAmount; redemptions = null });

    txIndex
  };


  /// get profile information
  public shared({ caller }) func getProfile(uid: ?T.UID): async T.UserProfile {
    switch(uid) {
      case(null) await UserIndex.getProfile(caller);
      case(?value) await UserIndex.getProfile(value);
    };
  };


  /// get beneficiaries
  public shared({ caller }) func getBeneficiaries(): async [T.UserProfile] {
    await UserIndex.getBeneficiaries(caller);
  };


  /// update beneficiaries
  public shared({ caller }) func addBeneficiaryRequested(notificationId: T.NotificationId): async() {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    let (_, notification) = await NotificationIndex.getNotification(notificationId);

    // validate notification provided
    switch(notification.eventStatus) {
      case(null) throw Error.reject("notification is not executable");
      case(?event) {
        switch(event) {
          case(#pending(status)) {};
          case(#declined(status)) throw Error.reject("notification status is " # status);
          case(#accepted(status)) throw Error.reject("notification status is " # status);
        };
      };
    };

    let triggeredBy = switch(notification.triggeredBy) {
      case(null) throw Error.reject("triggeredBy field cannot be null");
      case(?value) value;
    };

    await UserIndex.updateBeneficiaries(notification.receivedBy, triggeredBy, { delete = false });

    // change notification status
    let _ = await _updateEventNotification(caller, notificationId, ?#accepted("accepted"));
  };


  /// send beneficiary notification
  public shared({ caller }) func requestBeneficiary(beneficiaryId: T.BID): async() {
    // check if user exists and check beneficiary already added
    if (await UserIndex.checkBeneficiary(caller, beneficiaryId)) throw Error.reject("Beneficiary has already been added");

    // send beneficiary notification
    await _addNotification({
      id = "0";
      title = "Beneficiary request";
      content = null;
      notificationType = #beneficiary("beneficiary");
      tokenId = null;
      receivedBy = beneficiaryId;
      triggeredBy = ?caller;
      quantity = null;
      createdAt = DateTime.now().toText();
      status = null;
      eventStatus = ?#pending("pending");
    });
  };


  /// filter users on Cero Trade by name or principal id
  public shared({ caller }) func filterUsers(user: Text): async [T.UserProfile] { await UserIndex.filterUsers(caller, user) };


  /// function to know user token balance
  public shared({ caller }) func balanceOf(tokenId: T.TokenId): async T.TokenAmount { await TokenIndex.balanceOf(caller, tokenId) };

  /// get user portfolio information
  public shared({ caller }) func getPortfolio(page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    tokensInfo: { data: [T.TokenInfo]; totalPages: Nat; };
    tokensRedemption: [T.TransactionInfo]
  } {
    let tokenIds = await UserIndex.getPortfolioTokenIds(caller);
    var tokensInfo: {
      data: [T.TokenInfo];
      totalPages: Nat;
    } = await TokenIndex.getPortfolio(caller, tokenIds, page, length, assetTypes, country, mwhRange);

    for(token in tokensInfo.data.vals()) {
      if (token.totalAmount <= 0) {
        await UserIndex.updatePortfolio(caller, token.tokenId, { delete = true });

        let tokens = Buffer.fromArray<T.TokenInfo>(tokensInfo.data);

        switch (Buffer.indexOf<Text>(token.tokenId, Buffer.map<T.TokenInfo, Text>(tokens, func x =  x.tokenId ), Text.equal)) {
          case(null) {};
          case(?index) {
            let _ = tokens.remove(index);
            tokensInfo := { tokensInfo with data = Buffer.toArray<T.TokenInfo>(tokens) };
          };
        };
      }
    };

    let txIds = await UserIndex.getTransactionIds(caller);
    let tokensRedemption: [T.TransactionInfo] = await TransactionIndex.getTransactionsById(txIds, ?#redemption("redemption"), null, null, null, null);

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



  /// get token information
  public shared({ caller }) func getTokenDetails(tokenId: T.TokenId): async T.TokenInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    try {
      let tokenInfo: T.TokenInfo = await TokenIndex.getTokenPortfolio(caller, tokenId);
      let inMarket = await Marketplace.getAvailableTokens(tokenId);

      { tokenInfo with inMarket }
    } catch (error) {
      let assetInfo: T.AssetInfo = await TokenIndex.getAssetInfo(tokenId);
      let inMarket = await Marketplace.getAvailableTokens(tokenId);

      {
        tokenId;
        totalAmount = 0;
        inMarket;
        assetInfo;
      }
    }
  };


  /// get marketplace information
  public shared({ caller }) func getMarketplace(page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, priceRange: ?[T.Price]): async {
    data: [T.MarketplaceInfo];
    totalPages: Nat;
  } {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    Debug.print(debug_show ("before getMarketplace: " # Nat.toText(Cycles.balance())));

    let {
      data: [{
        tokenId: T.TokenId;
        mwh: T.TokenAmount;
        lowerPriceE8S: T.Price;
        higherPriceE8S: T.Price;
      }] = marketInfo;
      totalPages: Nat;
    } = await Marketplace.getMarketplace(page, length, priceRange);

    let tokensInfo: [T.AssetInfo] = await TokenIndex.getTokensInfo(Array.map<{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceE8S: T.Price;
      higherPriceE8S: T.Price;
    }, Text>(marketInfo, func x = x.tokenId));

    // map market and asset values to marketplace info
    let marketplace: [T.MarketplaceInfo] = Array.map<{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceE8S: T.Price;
      higherPriceE8S: T.Price;
    }, T.MarketplaceInfo>(marketInfo, func (item) {
      let assetInfo = Array.find<T.AssetInfo>(tokensInfo, func (info) { info.tokenId == item.tokenId });

      switch (assetInfo) {
        /// this case will not occur, just here to can compile
        case (null) {
          {
            tokenId = item.tokenId;
            mwh = item.mwh;
            lowerPriceE8S = item.lowerPriceE8S;
            higherPriceE8S = item.higherPriceE8S;
            assetInfo = {
              tokenId = item.tokenId;
              assetType = #Hydro("Hydro");
              startDate = "2024-04-29T19:43:34.000Z";
              endDate = "2024-05-29T19:48:31.000Z";
              co2Emission = "11.22";
              radioactivityEmnission = "10.20";
              volumeProduced: T.TokenAmount = 1000;
              deviceDetails = {
                name = "machine";
                deviceType = #Hydro("Hydro");
                description = "description";
              };
              specifications = {
                deviceCode = "200";
                capacity: T.TokenAmount = 1000;
                location = "location";
                latitude = 0.0;
                longitude = 1.0;
                address = "address anywhere";
                stateProvince = "chile";
                country = "chile";
              };
              dates = ["2024-04-29T19:43:34.000Z", "2024-05-29T19:48:31.000Z", "2024-05-29T19:48:31.000Z"];
            };
          }
        };

        case (?asset) {
          // build MarketplaceInfo object
          {
            tokenId = item.tokenId;
            mwh = item.mwh;
            lowerPriceE8S = item.lowerPriceE8S;
            higherPriceE8S = item.higherPriceE8S;
            assetInfo = asset;
          }
        };
      };
    });

    Debug.print(debug_show ("after getMarketplace: " # Nat.toText(Cycles.balance())));


    // Apply filters
    let filteredMarketplace: [T.MarketplaceInfo] = Array.filter<T.MarketplaceInfo>(marketplace, func (item) {
      // by assetTypes
      let assetTypeMatches = switch (assetTypes) {
        case(null) true;
        case(?assets) Array.find<T.AssetType>(assets, func (assetType) { assetType == item.assetInfo.assetType }) != null;
      };

      // by country
      let countryMatches = switch (country) {
        case(null) true;
        case(?value) item.assetInfo.specifications.country == value;
      };

      assetTypeMatches and countryMatches;
    });

    { data = filteredMarketplace; totalPages }
  };


  /// get marketplace sellers information
  public shared({ caller }) func getMarketplaceSellers(page: ?Nat, length: ?Nat, tokenId: ?T.TokenId, country: ?Text, priceRange: ?[T.Price], excludeCaller: Bool): async {
    data: [T.MarketplaceSellersInfo];
    totalPages: Nat;
  } {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    Debug.print(debug_show ("before getMarketplaceSellers: " # Nat.toText(Cycles.balance())));

    let excludedCaller: ?T.UID = switch(excludeCaller) {
      case(false) null;
      case(true) ?caller;
    };

    // get market info
    let {
      data: [{
        tokenId: T.TokenId;
        userId: T.UID;
        mwh: T.TokenAmount;
        priceE8S: T.Price;
      }] = marketInfo;
      totalPages: Nat;
    } = await Marketplace.getMarketplaceSellers(page, length, tokenId, priceRange, excludedCaller);

    // get tokens info
    let tokensInfo: [T.AssetInfo] = await TokenIndex.getTokensInfo(Array.map<{
      tokenId: T.TokenId;
      userId: T.UID;
      mwh: T.TokenAmount;
      priceE8S: T.Price;
    }, Text>(marketInfo, func x = x.tokenId));


    // map market and asset values to marketplace info
    let marketplace: [T.MarketplaceSellersInfo] = Array.map<{
      tokenId: T.TokenId;
      userId: T.UID;
      mwh: T.TokenAmount;
      priceE8S: T.Price;
    }, T.MarketplaceSellersInfo>(marketInfo, func (item) {

      let assetInfo: ?T.AssetInfo = Array.find<T.AssetInfo>(tokensInfo, func (info) { info.tokenId == item.tokenId });


      // build MarketplaceSellersInfo object
      {
        sellerId = item.userId;
        tokenId = item.tokenId;
        mwh = item.mwh;
        priceE8S = item.priceE8S;
        assetInfo;
      }
    });

    Debug.print(debug_show ("after getMarketplaceSellers: " # Nat.toText(Cycles.balance())));


    // Apply filters
    let filteredMarketplace: [T.MarketplaceSellersInfo] = Array.filter<T.MarketplaceSellersInfo>(marketplace, func (item) {
      // by country
      let countryMatches = switch (country) {
        case(null) true;
        case(?value) {
          switch(item.assetInfo) {
            case(null) false;
            case(?assetInfo) assetInfo.specifications.country == value;
          };
        };
      };

      countryMatches;
    });

    { data = filteredMarketplace; totalPages }
  };

  /// get canister id that allow current token
  public func getTokenCanister(tokenId: T.TokenId): async T.CanisterId {
    await TokenIndex.getTokenCanister(tokenId);
  };

  /// performe token purchase
  public shared({ caller }) func purchaseToken(tokenId: T.TokenId, recipent: T.BID, tokenAmount: T.TokenAmount): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // validate if recipent have enough tokens
    let tokensOnSale = await Marketplace.getUserTokensOnSale(recipent, tokenId);
    if (tokensOnSale < tokenAmount) throw Error.reject("Seller have not enough tokens on sell");

    // get seller token price in marketplace
    let priceE8S: T.Price = await Marketplace.getTokenPrice(tokenId, recipent);
    let totalPriceE8S = { priceE8S with e8s = priceE8S.e8s * Nat64.fromNat(tokenAmount) };

    // performe ICP transfer and update token canister
    let txIndex = await TokenIndex.purchaseToken(caller, recipent, tokenId, tokenAmount, totalPriceE8S);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = caller;
      to = ?recipent;
      tokenId;
      txType = #purchase("purchase");
      tokenAmount;
      priceE8S = ?totalPriceE8S;
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
    };

    // store token register on profile
    await UserIndex.updatePortfolio(caller, tokenId, { delete = false });

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    // store to caller
    await UserIndex.updateTransactions(caller, txId);

    // store to recipent
    await UserIndex.updateTransactions(recipent, txId);

    // take token off marketplace reference
    await Marketplace.takeOffSale(tokenId, tokenAmount, recipent);

    { txInfo with transactionId = txId }
  };


  /// ask market to put on sale token
  public shared({ caller }) func sellToken(tokenId: T.TokenId, quantity: T.TokenAmount, priceICP: Float): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check price higher than 0
    if (priceICP < 0) throw Error.reject("Price Must be higher than 0");

    // check balance
    let balance = await TokenIndex.balanceOf(caller, tokenId);


    // check if user is already selling
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let availableTokens: T.TokenAmount = balance - tokensInSale;

    // check if user has enough tokens
    if (availableTokens < quantity or quantity < 0) throw Error.reject("Not enough tokens to sell");

    // transfer tokens from user to marketplace
    let txIndex = await TokenIndex.sellInMarketplace(caller, tokenId, quantity);

    // transform icp to e8s
    let priceE8S = { e8s: Nat64 = Int64.toNat64(Float.toInt64(priceICP)) * T.getE8sEquivalence() };

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = caller;
      to = null;
      tokenId;
      txType = #putOnSale("putOnSale");
      tokenAmount = quantity;
      priceE8S = ?priceE8S;
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    // put tokens on marketplace reference
    await Marketplace.putOnSale(tokenId, quantity, caller, priceE8S);

    { txInfo with transactionId = txId }
  };


  // request to know if user is selling token provided in marketplace
  public shared({ caller }) func checkUserTokenInMarket(tokenId: T.TokenId): async Bool {
    await Marketplace.isSellingToken(caller, tokenId)
  };


  // ask market to take off market
  public shared ({ caller }) func takeTokenOffMarket(tokenId: T.TokenId, quantity: T.TokenAmount): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if user is already selling
    let isSelling = await Marketplace.isSellingToken(caller, tokenId);
    if (not isSelling) throw Error.reject("User is not selling this token");

    // check if user has enough tokens
    let tokenInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    if (tokenInSale < quantity) throw Error.reject("Not enough tokens owned in market");

    // transfer tokens from marketplace to user
    let txIndex = await TokenIndex.takeOffMarketplace(caller, tokenId, quantity);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = caller;
      to = null;
      tokenId;
      txType = #takeOffMarketplace("takeOffMarketplace");
      tokenAmount = quantity;
      priceE8S = null;
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    // take off tokens on marketplace reference
    await Marketplace.takeOffSale(tokenId, quantity, caller);

    { txInfo with transactionId = txId }
  };


  public shared({ caller }) func requestRedeemToken(tokenId: T.TokenId, quantity: T.TokenAmount, beneficiary: T.BID): async T.TxIndex {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // hold tokens until beneficiary performe redemption
    let txIndex = await TokenIndex.requestRedeem(caller, tokenId, quantity, { returns = false });

    // send redemption notification to beneficiary
    await _addNotification({
      id = "0";
      title = "Redemption request";
      content = null;
      notificationType = #redeem("redeem");
      tokenId = ?tokenId;
      receivedBy = beneficiary;
      triggeredBy = ?caller;
      quantity = ?quantity;
      createdAt = DateTime.now().toText();
      status = null;
      eventStatus = ?#pending("pending");
    });

    txIndex
  };

  // redeem certificate by burning user tokens
  public shared({ caller }) func redeemTokenRequested(notificationId: T.NotificationId): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // get redemption notification
    let (_, notification) = await NotificationIndex.getNotification(notificationId);

    // validate notification provided
    switch(notification.eventStatus) {
      case(null) throw Error.reject("notification is not executable");
      case(?event) {
        switch(event) {
          case(#pending(status)) {};
          case(#declined(status)) throw Error.reject("notification status is " # status);
          case(#accepted(status)) throw Error.reject("notification status is " # status);
        };
      };
    };

    let tokenId = switch(notification.tokenId) {
      case(null) throw Error.reject("tokenId not provided");
      case(?value) value;
    };
    let quantity = switch(notification.quantity) {
      case(null) throw Error.reject("quantity id not provided");
      case(?value) value;
    };

    // redeem tokens
    let txIndex = await TokenIndex.redeemRequested(notification);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = caller;
      to = ?caller;
      tokenId;
      txType = #redemption("redemption");
      tokenAmount = quantity;
      priceE8S = ?{ e8s = T.getCeroComission() + 20_000 };
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);

    // update receiver user transactions
    await UserIndex.updateTransactions(notification.receivedBy, txId);

    // update trigger user transactions
    let triggeredBy = switch(notification.triggeredBy) {
      case(null) throw Error.reject("triggeredBy not provided");
      case(?value) value;
    };
    await UserIndex.updateTransactions(triggeredBy, txId);

    // change notification status
    let _ = await _updateEventNotification(caller, notificationId, ?#accepted("accepted"));

    // register asset statistic
    await Statistics.registerAssetStatistic(tokenId, { mwh = null; redemptions = ?quantity });

    { txInfo with transactionId = txId }
  };

  // redeem certificate by burning user tokens
  public shared({ caller }) func redeemToken(tokenId: T.TokenId, quantity: T.TokenAmount): async T.TransactionInfo {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // check if token exists
    let tokenPortofolio = await TokenIndex.getTokenPortfolio(caller, tokenId);

    // check if user has enough tokens
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);
    let availableTokens: T.TokenAmount = tokenPortofolio.totalAmount - tokensInSale;

    if (availableTokens < quantity) throw Error.reject("Not enough tokens");

    // ask token to burn the tokens
    let txIndex = await TokenIndex.redeem(caller, tokenId, quantity);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = caller;
      to = ?caller;
      tokenId;
      txType = #redemption("redemption");
      tokenAmount = quantity;
      priceE8S = ?{ e8s = T.getCeroComission() + 20_000 };
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
    };

    // register transaction
    let txId = await TransactionIndex.registerTransaction(txInfo);
    await UserIndex.updateTransactions(caller, txId);

    // register asset statistic
    await Statistics.registerAssetStatistic(tokenId, { mwh = null; redemptions = ?quantity });

    { txInfo with transactionId = txId }
  };


  // get user transactions
  public shared({ caller }) func getTransactionsByUser(page: ?Nat, length: ?Nat, txType: ?T.TxType, country: ?Text, priceRange: ?[T.Price], mwhRange: ?[T.TokenAmount], assetTypes: ?[T.AssetType], method: ?T.TxMethod, rangeDates: ?[Text]): async {
    data: [T.TransactionHistoryInfo];
    totalPages: Nat;
  } {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // define page based on statement
    let startPage = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    let txIds = await UserIndex.getTransactionIds(caller);
    let txIdsFiltered = Buffer.Buffer<T.TransactionId>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    for (txId in txIds.vals()) {
      if (i >= startIndex and i < startIndex + maxLength) txIdsFiltered.add(txId);
      i += 1;
    };

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;


    let transactionsInfo: [T.TransactionInfo] = await TransactionIndex.getTransactionsById(Buffer.toArray<T.TransactionId>(txIdsFiltered), txType, priceRange, mwhRange, method, rangeDates);

    // get tokens info
    let tokensInfo: [T.AssetInfo] = await TokenIndex.getTokensInfo(Array.map<T.TransactionInfo, Text>(transactionsInfo, func x = x.tokenId));


    // map market and asset values to marketplace info
    let transactions: [T.TransactionHistoryInfo] = Array.map<T.TransactionInfo, T.TransactionHistoryInfo>(transactionsInfo, func (item) {

      let assetInfo: ?T.AssetInfo = Array.find<T.AssetInfo>(tokensInfo, func (info) { info.tokenId == item.tokenId });


      // build MarketplaceSellersInfo object
      {
        transactionId = item.transactionId;
        txIndex = item.txIndex;
        txType = item.txType;
        tokenAmount = item.tokenAmount;
        priceE8S = item.priceE8S;
        date = item.date;
        method = item.method;
        from = item.from;
        to = item.to;
        assetInfo;
      }
    });


    // Apply filters
    let filteredTransactions: [T.TransactionHistoryInfo] = Array.filter<T.TransactionHistoryInfo>(transactions, func (item) {
      // by country
      let countryMatches = switch (country) {
        case(null) true;
        case(?value) {
          switch(item.assetInfo) {
            case(null) false;
            case(?assetInfo) assetInfo.specifications.country == value;
          };
        };
      };

      // by assetTypes
      let assetTypeMatches = switch (assetTypes) {
        case(null) true;
        case(?assets) {
          switch(item.assetInfo) {
            case(null) false;
            case(?asset) Array.find<T.AssetType>(assets, func (assetType) { assetType == asset.assetType }) != null;
          };
        };
      };

      countryMatches and assetTypeMatches;
    });

    {
      data = filteredTransactions;
      totalPages
    }
  };


  // get all asset statistics
  public func getAllAssetStatistics(): async [(T.TokenId, T.AssetStatistic)] { await Statistics.getAllAssetStatistics() };

  // get asset statistics
  public func getAssetStatistics(tokenId: T.TokenId): async T.AssetStatistic { await Statistics.getAssetStatistics(tokenId) };


  // get notifications
  public shared({ caller }) func getNotifications(page: ?Nat, length: ?Nat, notificationTypes: [T.NotificationType]): async [T.NotificationInfo] {
    let token = await UserIndex.getUserToken(caller);
    await NotificationIndex.getNotifications(token, page, length, notificationTypes);
  };


  // add notification
  private func _addNotification(notification: T.NotificationInfo): async() {
    let receiverToken = await UserIndex.getUserToken(notification.receivedBy);

    let triggerToken: ?T.UserToken = switch(notification.triggeredBy) {
      case(null) null;
      case(?triggerUser) {
        if (notification.notificationType == #general("general")) { null } else {
          let token = await UserIndex.getUserToken(triggerUser);
          ?token
        }
      };
    };

    await NotificationIndex.addNotification(receiverToken, triggerToken, notification);
  };


  // update general notifications
  public shared({ caller }) func updateGeneralNotifications(notificationIds: [T.NotificationId]) : async() {
    let token = await UserIndex.getUserToken(caller);
    await NotificationIndex.updateGeneralNotifications(token, notificationIds);
  };

  // clear general notifications
  public shared({ caller }) func clearGeneralNotifications(notificationIds: [T.NotificationId]): async() {
    let token = await UserIndex.getUserToken(caller);
    await NotificationIndex.clearGeneralNotifications(token, notificationIds);
  };

  // update event notification
  public shared({ caller }) func updateEventNotification(notificationId: T.NotificationId, eventStatus: ?T.NotificationEventStatus): async ?T.TxIndex {
    await _updateEventNotification(caller, notificationId, eventStatus);
  };

  // helper function to performe updateEventNotification
  private func _updateEventNotification(caller: T.UID, notificationId: T.NotificationId, eventStatus: ?T.NotificationEventStatus): async ?T.TxIndex {
    let (cid, notification) = await NotificationIndex.getNotification(notificationId);

    let receiver = await UserIndex.getUserToken(notification.receivedBy);

    let trigger: ?T.UserToken = switch(notification.triggeredBy) {
      case(null) null;
      case(?triggerUser) {
        if (notification.notificationType == #general("general")) { null } else {
          let token = await UserIndex.getUserToken(triggerUser);
          ?token
        }
      };
    };

    let redemptionCancelled = await NotificationIndex.updateEventNotification(caller, { receiver; trigger }, (cid, notification), eventStatus);
    if (not redemptionCancelled) return null;

    // flow to return holded tokens
    let triggerUser = switch(notification.triggeredBy) {
      case(null) throw Error.reject("triggeredBy not provided");
      case(?value) value;
    };
    let tokenId = switch(notification.tokenId) {
      case(null) throw Error.reject("tokenId not provided");
      case(?value) value;
    };
    let quantity = switch(notification.quantity) {
      case(null) throw Error.reject("quantity not provided");
      case(?value) value;
    };

    // return tokens holded on token canister if trigger performe cancelation
    let txIndex = await TokenIndex.requestRedeem(triggerUser, tokenId, quantity, { returns = true });
    ?txIndex
  };
}
