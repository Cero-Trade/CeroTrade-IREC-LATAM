import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import DateTime "mo:datetime/DateTime";

// canisters
import UserIndex "canister:user_index";
import TokenIndex "canister:token_index";
import TransactionIndex "canister:transaction_index";
import Marketplace "canister:marketplace";
import Statistics "canister:statistics";
import BucketIndex "canister:bucket_index";

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
    Debug.print("logged user with principal --> " # Principal.toText(caller));

    let exists = await UserIndex.checkPrincipal(caller);
    if (not exists) throw Error.reject(notExists);
  };


  /// register user into Cero Trade
  public shared({ caller }) func register(form: T.RegisterForm, beneficiary: ?T.BID): async() {
    await UserIndex.registerUser(caller, form, beneficiary)
  };


  /// store user avatar into users collection
  public shared({ caller }) func storeCompanyLogo(avatar: T.ArrayFile): async() { await UserIndex.storeCompanyLogo(caller, avatar) };

  /// update user into Cero Trade
  public shared({ caller }) func updateUserInfo(form: T.UpdateUserForm): async() { await UserIndex.updateUserInfo(caller, form) };

  /// delete user into Cero Trade
  public shared({ caller }) func deleteUser(): async() {
    // check if caller exists and return companyName
    let callerName = await UserIndex.getUserName(caller);

    let portfolio: {
      data: [T.Portfolio];
      totalPages: Nat;
    } = await _getPortfolio(caller, null, null, null, null, null);

    for({ tokenInfo; } in portfolio.data.vals()) {
      // check if user has enough tokens
      let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenInfo.tokenId);
      if (tokensInSale > 0) {
        // take off tokens on marketplace reference
        let _ = await Marketplace.takeOffSale(tokenInfo.tokenId, tokensInSale, caller);
      };

      // burn user tokens
      let txs = await TokenIndex.burnUserTokens(caller, tokenInfo.tokenId, tokenInfo.totalAmount, tokensInSale);

      for({ tokenAmount; txIndex; } in txs.vals()) {
        // build transaction
        let txInfo: T.TransactionInfo = {
          transactionId = "0";
          txIndex;
          from = { principal = caller; name = callerName };
          to = null;
          tokenId = tokenInfo.tokenId;
          txType = #burn("burn");
          tokenAmount;
          priceE8S = null;
          date = DateTime.now().toText();
          method = #blockchainTransfer("blockchainTransfer");
          redemptionPdf = null;
        };

        // register transaction
        let _txId = await TransactionIndex.registerTransaction(txInfo);
      };

      // remove tokens from statistics
      await Statistics.removeAssetStatistic(tokenInfo.tokenId, tokenInfo.totalAmount);
    };

    // delete user
    await UserIndex.deleteUser(caller)
  };

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
    await BucketIndex.registerControllers();
  };

  /// register a canister wasm module
  public shared({ caller }) func registerWasmModule(moduleName: IC_MANAGEMENT.WasmModuleName): async() {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(moduleName) {
      case(#token("token")) await TokenIndex.registerWasmArray();
      case(#users("users")) await UserIndex.registerWasmArray();
      case(#transactions("transactions")) await TransactionIndex.registerWasmArray();
      case(#bucket("bucket")) await BucketIndex.registerWasmArray();
      case _ throw Error.reject("Module name doesn't exists");
    };
  };

  /// delete all deployed canisters
  ///
  /// only delete one if provide canister id
  ///
  /// when provide moduleName null all canisters will be deleted
  public shared({ caller }) func deleteDeployedCanister(moduleName: ?IC_MANAGEMENT.WasmModuleName, cid: ?T.CanisterId): async() {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(moduleName) {
      case(null) {
        await TokenIndex.deleteDeployedCanister(null);
        await UserIndex.deleteDeployedCanister(null);
        await TransactionIndex.deleteDeployedCanister(null);
        await BucketIndex.deleteDeployedCanister(null);
      };
      case(?value) switch(value) {
        case(#token("token")) await TokenIndex.deleteDeployedCanister(cid);
        case(#users("users")) await UserIndex.deleteDeployedCanister(cid);
        case(#transactions("transactions")) await TransactionIndex.deleteDeployedCanister(cid);
        case(#bucket("bucket")) await BucketIndex.deleteDeployedCanister(cid);
        case _ throw Error.reject("Module name doesn't exists");
      };
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
    // performe import of tokens
    let transactions = await TokenIndex.importUserTokens(caller);

    let mappedTxs = Buffer.Buffer<{ tokenId: T.TokenId; statistics: { mwh: ?T.TokenAmount; redemptions: ?T.TokenAmount } }>(16);
    let mappedAssets = Buffer.Buffer<T.AssetInfo>(16);

    for({ mwh; assetInfo } in transactions.vals()) {
      mappedAssets.add(assetInfo);

      mappedTxs.add({
        tokenId = assetInfo.tokenId;
        statistics = { mwh = ?mwh; redemptions = null };
      });
    };

    // add user portfolio
    await UserIndex.addTokensPortfolio(caller, Buffer.toArray(mappedAssets));

    // register asset statistic
    await Statistics.registerAssetStatistics(Buffer.toArray(mappedTxs));

    transactions
  };


  /// performe mint with tokenId and amount requested
  public shared({ caller }) func mintTokenToUser(recipent: T.BID, tokenId: T.TokenId, tokenAmount: T.TokenAmount): async T.TxIndex {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    // check if user exists
    if (not (await UserIndex.checkPrincipal(recipent))) throw Error.reject(notExists);

    // mint token to user token collection
    let (txIndex, assetInfo) = await TokenIndex.mintTokenToUser(recipent, tokenId, tokenAmount);

    // add user portfolio
    await UserIndex.addTokensPortfolio(recipent, [assetInfo]);

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

    let notification = await UserIndex.getNotification(caller, notificationId);

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

    await UserIndex.addBeneficiary(notification.receivedBy, triggeredBy);

    // change notification status
    let _ = await _updateEventNotification(caller, notificationId, ?#accepted("accepted"));
  };


  /// send beneficiary notification
  public shared({ caller }) func requestBeneficiary(beneficiaryId: T.BID): async() {
    // check if user exists and check beneficiary already added
    if (await UserIndex.checkBeneficiary(caller, beneficiaryId)) throw Error.reject("Beneficiary has already been added");

    // send beneficiary notification
    await UserIndex.addNotification({
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
      redeemPeriodStart = null;
      redeemPeriodEnd = null;
      redeemLocale = null;
    });
  };


  /// filter users on Cero Trade by name or principal id
  public shared({ caller }) func filterUsers(input: Text): async [{ principalId: T.UID; companyName: Text }] {
    await UserIndex.filterUsers(caller, input)
  };


  /// function to know user token balance
  public shared({ caller }) func balanceOf(tokenId: T.TokenId): async T.TokenAmount { await TokenIndex.balanceOf(caller, tokenId) };

  /// get user single portfolio information
  public shared({ caller }) func getSinglePortfolio(tokenId: T.TokenId): async T.SinglePortfolio {
    await _getSinglePortfolio(caller, tokenId);
  };

  // helper function to get single portfolio
  private func _getSinglePortfolio(caller: T.UID, tokenId: T.TokenId): async T.SinglePortfolio {
    let singlePortfolio = await UserIndex.getSinglePortfolio(caller, tokenId);

    switch(singlePortfolio) {
      case(#ok(portfolio)) {
        let balance = await TokenIndex.balanceOf(caller, portfolio.tokenInfo.tokenId);
        { portfolio with tokenInfo = { portfolio.tokenInfo with totalAmount = balance } };
      };

      case(#err(error)) {
        let tokenInfo = await TokenIndex.getSingleTokenInfo(caller, tokenId);
        { tokenInfo; redemptions = []; };
      };
    };
  };

  /// get user portfolio information
  public shared({ caller }) func getPortfolio(page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    data: [T.Portfolio];
    totalPages: Nat;
  } {
    await _getPortfolio(caller, page, length, assetTypes, country, mwhRange);
  };

  // helper function to get portfolio
  private func _getPortfolio(caller: T.UID, page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    data: [T.Portfolio];
    totalPages: Nat;
  } {
    let filteredPortfolio = await UserIndex.getPortfolio(caller, page, length, assetTypes, country, mwhRange);
    let balances: [(T.TokenId, Nat)] = await TokenIndex.balanceOfBatch(
      caller,
      Array.map<T.Portfolio, T.TokenId>(filteredPortfolio.data, func x = x.tokenInfo.tokenId)
    );

    // Convert tokensInfo to a HashMap for faster lookup
    let tokenBalances = HM.fromIter<T.TokenId, Nat>(Iter.fromArray(balances), 16, Text.equal, Text.hash);


    // map filteredPortfolio and tokenBalances values to portfolio info
    let portfolio: [T.Portfolio] = Array.map<T.Portfolio, T.Portfolio>(filteredPortfolio.data, func (item) {
      let balance = switch(tokenBalances.get(item.tokenInfo.tokenId)) {
        case(null) 0;
        case(?value) value;
      };

      { item with tokenInfo = { item.tokenInfo with totalAmount = balance }  }
    });

    // divide tokens without balance and tokens with balance
    let (shouldKeep, shouldNotKeep): (List.List<T.Portfolio>, List.List<T.Portfolio>) = List.partition<T.Portfolio>(List.fromArray<T.Portfolio>(portfolio), func (item) {
      item.tokenInfo.totalAmount > 0 or item.tokenInfo.inMarket > 0 or item.redemptions.size() > 0
    });

    // remove tokens without balance
    if (List.size(shouldNotKeep) > 0) await UserIndex.removeTokensPortfolio(
        caller,
        Array.map<T.Portfolio, T.TokenId>(List.toArray<T.Portfolio>(shouldNotKeep), func x = x.tokenInfo.tokenId)
      );

    {
      data = List.toArray<T.Portfolio>(shouldKeep);
      totalPages = filteredPortfolio.totalPages;
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

    // Convert tokensInfo to a HashMap for faster lookup
    let tokensInfoMap = HM.fromIter<T.TokenId, T.AssetInfo>(Iter.fromArray(Array.map<T.AssetInfo, (T.TokenId, T.AssetInfo)>(tokensInfo, func info = (info.tokenId, info))), 16, Text.equal, Text.hash);


    // map market and asset values to marketplace info
    let marketplace: [T.MarketplaceInfo] = Array.map<{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceE8S: T.Price;
      higherPriceE8S: T.Price;
    }, T.MarketplaceInfo>(marketInfo, func (item) {
      let assetInfo = tokensInfoMap.get(item.tokenId);

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
              startDate = "2024-04-29T19:43:34.000Z";
              endDate = "2024-05-29T19:48:31.000Z";
              co2Emission = "11.22";
              radioactivityEmission = "10.20";
              volumeProduced: T.TokenAmount = 1000;
              deviceDetails = {
                name = "machine";
                deviceType = #HydroElectric("Hydro-Electric");
                description = "description";
              };
              specifications = {
                deviceCode = "200";
                location = "location";
                latitude = "0.1";
                longitude = "1.0";
                country = "CL";
              };
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
        case(?assets) Array.find<T.AssetType>(assets, func (assetType) { assetType == item.assetInfo.deviceDetails.deviceType }) != null;
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
    data: [T.MarketplaceSellersResponse];
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
      data: [T.MarketplaceSellersInfo] = marketInfo;
      totalPages: Nat;
    } = await Marketplace.getMarketplaceSellers(page, length, tokenId, priceRange, excludedCaller);

    // get tokens info
    let tokensInfo: [T.AssetInfo] = await TokenIndex.getTokensInfo(Array.map<T.MarketplaceSellersInfo, Text>(marketInfo, func x = x.tokenId));

    // Convert tokensInfo to a HashMap for faster lookup
    let tokensInfoMap = HM.fromIter<T.TokenId, T.AssetInfo>(Iter.fromArray(Array.map<T.AssetInfo, (T.TokenId, T.AssetInfo)>(tokensInfo, func info = (info.tokenId, info))), 16, Text.equal, Text.hash);


    // map market and asset values to marketplace info
    let marketplace: [T.MarketplaceSellersResponse] = Array.map<T.MarketplaceSellersInfo, T.MarketplaceSellersResponse>(marketInfo, func (item) {
      let assetInfo = tokensInfoMap.get(item.tokenId);

      // build MarketplaceSellersResponse object
      {
        sellerId = item.sellerId;
        sellerName = item.sellerName;
        tokenId = item.tokenId;
        mwh = item.mwh;
        priceE8S = item.priceE8S;
        assetInfo;
      }
    });

    Debug.print(debug_show ("after getMarketplaceSellers: " # Nat.toText(Cycles.balance())));


    // Apply filters
    let filteredMarketplace: [T.MarketplaceSellersResponse] = Array.filter<T.MarketplaceSellersResponse>(marketplace, func (item) {
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
    // check if caller exists and return companyName
    let callerName = await UserIndex.getUserName(caller);

    // check if recipent exists and return companyName
    let recipentName = await UserIndex.getUserName(recipent);

    // validate if recipent have enough tokens
    let tokensOnSale = await Marketplace.getUserTokensOnSale(recipent, tokenId);
    if (tokensOnSale < tokenAmount) throw Error.reject("Seller have not enough tokens on sell");

    // get seller token price in marketplace
    let priceE8S: T.Price = await Marketplace.getTokenPrice(tokenId, recipent);

    // calc price based on how many tokens will be purchased
    let totalPriceE8S = {
      priceE8S with e8s: Nat64 = (priceE8S.e8s * Nat64.fromNat(tokenAmount)) / Nat64.pow(10, Nat64.fromNat(Nat8.toNat(T.tokenDecimals)))
    };

    // performe ICP transfer and update token canister
    let (txIndex, assetInfo) = await TokenIndex.purchaseToken(caller, recipent, tokenId, tokenAmount, totalPriceE8S);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = { principal = caller; name = callerName; };
      to = ?{ principal = recipent; name = recipentName; };
      tokenId;
      txType = #purchase("purchase");
      tokenAmount;
      priceE8S = ?totalPriceE8S;
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
      redemptionPdf = null;
    };

    // register transaction
    let transactionId = await TransactionIndex.registerTransaction(txInfo);

    // take token off marketplace reference
    let amountInMarket = await Marketplace.takeOffSale(tokenId, tokenAmount, recipent);

    // store to caller and recipent
    await UserIndex.updateMarketplace(caller, { amountInMarket; transaction = { txInfo with transactionId } }, ?{ recipent; assetInfo; });

    { txInfo with transactionId }
  };


  /// ask market to put on sale token
  public shared({ caller }) func sellToken(tokenId: T.TokenId, quantity: T.TokenAmount, priceE8S: T.Price): async T.TransactionInfo {
    // check if user exists and return companyName
    let sellerName = await UserIndex.getUserName(caller);

    // check price higher than 0
    if (priceE8S.e8s < 0) throw Error.reject("Price Must be higher than 0");

    // check balance
    let balance = await TokenIndex.balanceOf(caller, tokenId);


    // check if user is already selling
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);

    if (balance < tokensInSale) throw Error.reject("Not enough tokens to sell");
    let availableTokens: T.TokenAmount = balance - tokensInSale;

    // check if user has enough tokens
    if (availableTokens < quantity or quantity < 0) throw Error.reject("Not enough tokens to sell");

    // transfer tokens from user to marketplace
    let txIndex = await TokenIndex.sellInMarketplace(caller, tokenId, quantity);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = { principal = caller; name = sellerName; };
      to = null;
      tokenId;
      txType = #putOnSale("putOnSale");
      tokenAmount = quantity;
      priceE8S = ?priceE8S;
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
      redemptionPdf = null;
    };

    // register transaction
    let transactionId = await TransactionIndex.registerTransaction(txInfo);

    // put tokens on marketplace reference
    let amountInMarket = await Marketplace.putOnSale(tokenId, quantity, { sellerId = caller; sellerName }, priceE8S);

    // store to caller
    await UserIndex.updateMarketplace(caller, { amountInMarket; transaction = { txInfo with transactionId } }, null);

    { txInfo with transactionId }
  };


  // request to know if user is selling token provided in marketplace
  public shared({ caller }) func checkUserTokenInMarket(tokenId: T.TokenId): async Bool {
    await Marketplace.isSellingToken(caller, tokenId)
  };


  // helper function to ask market to take off market
  private func _takeTokenOffMarket(uid: T.UID, tokenId: T.TokenId, quantity: T.TokenAmount): async T.TransactionInfo {
    // check if user exists and return companyName
    let callerName = await UserIndex.getUserName(uid);

    // check if user is already selling
    let isSelling = await Marketplace.isSellingToken(uid, tokenId);
    if (not isSelling) throw Error.reject("User is not selling this token");

    // check if user has enough tokens
    let tokenInSale = await Marketplace.getUserTokensOnSale(uid, tokenId);
    if (tokenInSale < quantity) throw Error.reject("Not enough tokens owned in market");

    // transfer tokens from marketplace to user
    let txIndex = await TokenIndex.takeOffMarketplace(uid, tokenId, quantity);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = { principal = uid; name = callerName; };
      to = null;
      tokenId;
      txType = #takeOffMarketplace("takeOffMarketplace");
      tokenAmount = quantity;
      priceE8S = null;
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
      redemptionPdf = null;
    };

    // register transaction
    let transactionId = await TransactionIndex.registerTransaction(txInfo);

    // take off tokens on marketplace reference
    let amountInMarket = await Marketplace.takeOffSale(tokenId, quantity, uid);

    // store to uid
    await UserIndex.updateMarketplace(uid, { amountInMarket; transaction = { txInfo with transactionId } }, null);

    { txInfo with transactionId }
  };
  
  // ask market to take off market
  public shared ({ caller }) func takeTokenOffMarket(tokenId: T.TokenId, quantity: T.TokenAmount): async T.TransactionInfo {
    await _takeTokenOffMarket(caller, tokenId, quantity);
  };

  // force user to take off market
  public shared ({ caller }) func forceTakeTokenOffMarket(uid: T.UID, tokenId: T.TokenId, quantity: T.TokenAmount): async T.TransactionInfo {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    await _takeTokenOffMarket(uid, tokenId, quantity);
  };


  public shared({ caller }) func requestRedeemToken(tokenId: T.TokenId, quantity: T.TokenAmount, beneficiary: T.BID, periodStart: Text, periodEnd: Text, locale: Text): async T.TxIndex {
    // check if user exists
    if (not (await UserIndex.checkPrincipal(caller))) throw Error.reject(notExists);

    // hold tokens until beneficiary performe redemption
    let txIndex = await TokenIndex.requestRedeem(caller, tokenId, quantity, { returns = false });

    // send redemption notification to beneficiary
    await UserIndex.addNotification({
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
      redeemPeriodStart = ?periodStart;
      redeemPeriodEnd = ?periodEnd;
      redeemLocale = ?locale;
    });

    txIndex
  };

  // redeem certificate by burning user tokens
  public shared({ caller }) func redeemTokenRequested(notificationId: T.NotificationId): async T.TransactionInfo {
    // get redemption notification
    let notification = await UserIndex.getNotification(caller, notificationId);

    // check if caller exists and return companyName
    let profile = await UserIndex.getProfile(notification.receivedBy);

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

    let triggeredBy = switch(notification.triggeredBy) {
      case(null) throw Error.reject("triggeredBy not provided");
      case(?value) value;
    };

    // redeem tokens
    let { txIndex; redemptionPdf } = await TokenIndex.redeemRequested(profile, notification);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = { principal = caller; name = profile.companyName; };
      to = ?{ principal = caller; name = profile.companyName; };
      tokenId;
      txType = #redemption("redemption");
      tokenAmount = quantity;
      /// cero trade comission + transaction fee estimated
      priceE8S = ?{ e8s = T.getCeroComission() + 20_000 };
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
      redemptionPdf = ?redemptionPdf;
    };

    // register transaction
    let transactionId = await TransactionIndex.registerTransaction(txInfo);

    // update receiver and trigger user transactions
    await UserIndex.updateRedemptions(notification.receivedBy, ?triggeredBy, { txInfo with transactionId });

    // change notification status
    let _ = await _updateEventNotification(caller, notificationId, ?#accepted("accepted"));

    // register asset statistic
    await Statistics.registerAssetStatistic(tokenId, { mwh = null; redemptions = ?quantity });

    { txInfo with transactionId }
  };

  // redeem certificate by burning user tokens
  public shared({ caller }) func redeemToken(tokenId: T.TokenId, quantity: T.TokenAmount, periodStart: Text, periodEnd: Text, locale: Text): async T.TransactionInfo {
    // check if caller exists and return companyName
    let profile = await UserIndex.getProfile(caller);

    // check if token exists
    let tokenPortfolio = await _getSinglePortfolio(caller, tokenId);

    // check if user has enough tokens
    let tokensInSale = await Marketplace.getUserTokensOnSale(caller, tokenId);

    if (tokenPortfolio.tokenInfo.totalAmount < tokensInSale) throw Error.reject("Not enough tokens in portfolio");
    let availableTokens: T.TokenAmount = tokenPortfolio.tokenInfo.totalAmount - tokensInSale;
    if (availableTokens < quantity) throw Error.reject("Not enough tokens in portfolio");

    // ask token to burn the tokens
    let { txIndex; redemptionPdf; } = await TokenIndex.redeem(caller, profile.evidentBID, tokenId, quantity, periodStart, periodEnd, locale);

    // build transaction
    let txInfo: T.TransactionInfo = {
      transactionId = "0";
      txIndex;
      from = { principal = caller; name = profile.companyName; };
      to = ?{ principal = caller; name = profile.companyName; };
      tokenId;
      txType = #redemption("redemption");
      tokenAmount = quantity;
      /// cero trade comission + transaction fee estimated
      priceE8S = ?{ e8s = T.getCeroComission() + 20_000 };
      date = DateTime.now().toText();
      method = #blockchainTransfer("blockchainTransfer");
      redemptionPdf = ?redemptionPdf;
    };

    // register transaction
    let transactionId = await TransactionIndex.registerTransaction(txInfo);

    // store to caller
    await UserIndex.updateRedemptions(caller, null, { txInfo with transactionId });

    // register asset statistic
    await Statistics.registerAssetStatistic(tokenId, { mwh = null; redemptions = ?quantity });

    { txInfo with transactionId }
  };


  // get user transactions
  public shared({ caller }) func getTransactionsByUser(page: ?Nat, length: ?Nat, txType: ?T.TxType, country: ?Text, priceRange: ?[T.Price], mwhRange: ?[T.TokenAmount], assetTypes: ?[T.AssetType], method: ?T.TxMethod, rangeDates: ?[Text], tokenId: ?T.TokenId): async {
    data: [T.TransactionHistoryInfo];
    totalPages: Nat;
  } {
    let txIdsFiltered: {
      data: [T.TransactionId];
      totalPages: Nat;
    } = await UserIndex.getTransactionIds(caller, page, length);


    let transactionsInfo: [T.TransactionInfo] = await TransactionIndex.getTransactionsById(txIdsFiltered.data, txType, priceRange, mwhRange, method, rangeDates, tokenId);

    // get tokens info
    let tokensInfo: [T.AssetInfo] = await TokenIndex.getTokensInfo(Array.map<T.TransactionInfo, Text>(transactionsInfo, func x = x.tokenId));

    // Convert tokensInfo to a HashMap for faster lookup
    let tokensInfoMap = HM.fromIter<T.TokenId, T.AssetInfo>(Iter.fromArray(Array.map<T.AssetInfo, (T.TokenId, T.AssetInfo)>(tokensInfo, func info = (info.tokenId, info))), 16, Text.equal, Text.hash);


    // map market and asset values to marketplace info
    let transactions: [T.TransactionHistoryInfo] = Array.map<T.TransactionInfo, T.TransactionHistoryInfo>(transactionsInfo, func (item) {
      let assetInfo = tokensInfoMap.get(item.tokenId);


      // build TransactionHistoryInfo object
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
        redemptionPdf = item.redemptionPdf;
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
            case(?asset) Array.find<T.AssetType>(assets, func (assetType) { assetType == asset.deviceDetails.deviceType }) != null;
          };
        };
      };

      countryMatches and assetTypeMatches;
    });

    {
      data = filteredTransactions;
      totalPages = txIdsFiltered.totalPages;
    }
  };


  // get all asset statistics
  public func getAllAssetStatistics(): async [(T.TokenId, T.AssetStatistic)] { await Statistics.getAllAssetStatistics() };

  // get asset statistics
  public func getAssetStatistics(tokenId: T.TokenId): async T.AssetStatistic { await Statistics.getAssetStatistics(tokenId) };


  // get notifications
  public shared({ caller }) func getNotifications(page: ?Nat, length: ?Nat, notificationTypes: [T.NotificationType]): async {
    data: [T.NotificationInfo];
    totalPages: Nat;
  } {
    await UserIndex.getNotifications(caller, page, length, notificationTypes);
  };

  // update general notifications
  public shared({ caller }) func updateGeneralNotifications(notificationIds: ?[T.NotificationId]) : async() {
    await UserIndex.updateGeneralNotifications(caller, notificationIds);
  };

  // clear notifications
  public shared({ caller }) func clearNotifications(notificationIds: ?[T.NotificationId]): async() {
    await UserIndex.clearNotifications(caller, notificationIds);
  };

  // update event notification
  public shared({ caller }) func updateEventNotification(notificationId: T.NotificationId, eventStatus: ?T.NotificationEventStatus): async ?T.TxIndex {
    await _updateEventNotification(caller, notificationId, eventStatus);
  };

  // helper function to performe updateEventNotification
  private func _updateEventNotification(caller: T.UID, notificationId: T.NotificationId, eventStatus: ?T.NotificationEventStatus): async ?T.TxIndex {
    switch(await UserIndex.updateEventNotification(caller, notificationId, eventStatus)) {
      case(null) null;

      case(?notification) {
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
    };
  };
}
