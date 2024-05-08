import Error "mo:base/Error";

import MarketplaceTypes = "./marketplace_types";
import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

// types
import T "../types";
import ENV "../env";

actor class Marketplace() = this {

  var tokensInMarket : HM.HashMap<T.TokenId, T.TokenMarketInfo> = HM.HashMap(100, Text.equal, Text.hash);
  stable var tokensInMarketEntries : [(T.TokenId, T.TokenAmount, [(T.UID, T.UserTokenInfo)])] = [];

  /// funcs to persistent collection state
  system func preupgrade() {
    let marketplace = Buffer.Buffer<(T.TokenId, T.TokenAmount, [(T.UID, T.UserTokenInfo)])>(100);

    for ((tokenId, value) in tokensInMarket.entries()) {
      let usersxToken = Buffer.Buffer<((T.UID, T.UserTokenInfo))>(100);

      for ((key2, value2) in value.usersxToken.entries()) {
        usersxToken.add( (key2, value2) )
      };

      marketplace.add( (tokenId, value.totalQuantity, Buffer.toArray<(T.UID, T.UserTokenInfo)>(usersxToken)) );
    };

    tokensInMarketEntries := Buffer.toArray<(T.TokenId, T.TokenAmount, [(T.UID, T.UserTokenInfo)])>(marketplace)
  };

  system func postupgrade() {
    for ((key, totalQuantity, users) in tokensInMarketEntries.vals()) {
      var usersxToken = HM.HashMap<T.UID, T.UserTokenInfo>(100, Principal.equal, Principal.hash);

      for ((key2, value2) in users.vals()) {
        usersxToken.put(key2, value2);
      };

      tokensInMarket.put(key, { totalQuantity; usersxToken });
    };
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.AGENT_CANISTER_ID) == caller or Principal.fromActor(this) == caller };



  // check if token is already on the market
  public shared({ caller }) func isOnMarket(tokenId : T.TokenId) : async Bool {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) { return false };
      case (?_) { return true };
    };
  };

  // check if user is already selling a token
  public shared({ caller }) func isSellingToken(user : T.UID, tokenId : T.TokenId): async Bool {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) { return false };
      case (?info) {
        switch (info.usersxToken.get(user)) {
          case (null) {
            return false;
          };
          case (?info) {
            return true;
          };
        };
      };
    };
  };

  // new token in market
  private func _newTokensInMarket(tokenId : T.TokenId, user : T.UID, quantity : T.TokenAmount, priceICP: T.Price): async () {
    // user is selling a new token
    let usersxToken = HM.HashMap<T.UID, T.UserTokenInfo>(4, Principal.equal, Principal.hash);

    let userxTokenInfo = {
      quantity;
      priceICP;
    };

    usersxToken.put(user, userxTokenInfo);

    // update the market info for the token
    let tokenMarketInfo = {
      totalQuantity = quantity;
      usersxToken = usersxToken;
    };

    // add new information to the token market info
    tokensInMarket.put(tokenId, tokenMarketInfo);
  };

  // update token information
  private func _updatetokenMarketInfo(user : T.UID, tokenId : T.TokenId, quantity : T.TokenAmount, priceICP: T.Price): async () {
    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        throw Error.reject("Token not found in the market");
      };
      case (?info) {
        // Update the existing sale
        switch (info.usersxToken.get(user)) {
          case (null) {
            throw Error.reject("User is not selling this token");
          };
          case (?usersxTokenInfo) {
            // update the quantity
            let newQuantity = usersxTokenInfo.quantity + quantity;

            let updatedUserxToken = {
              quantity = newQuantity;
              priceICP;
            };

            info.usersxToken.put(user, updatedUserxToken);
            // update tokens in market quantity
            let updatedQuantity = info.totalQuantity + quantity;
            let updatedInfo = {
              totalQuantity = updatedQuantity;
              usersxToken = info.usersxToken;
            };
            tokensInMarket.put(tokenId, updatedInfo);
          };
        };
      };
    };
  };

  // handles new token information on market
  public shared({ caller }) func putOnSale(tokenId : T.TokenId, quantity : T.TokenAmount, user : T.UID, priceICP: T.Price) : async () {
    _callValidation(caller);

    // Check if the user is already selling the token
    let isSelling = await isSellingToken(user, tokenId);
    if (isSelling != false) {
      // update the existing sale
      await _updatetokenMarketInfo(user, tokenId, quantity, priceICP);
    } else {
      // add the new sale
      await _newTokensInMarket(tokenId, user, quantity, priceICP);
    };
  };

  // check how many token id is available for sale
  public shared({ caller }) func getAvailableTokens(tokenId : T.TokenId) : async T.TokenAmount {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        return 0;
      };
      case (?info) {
        return info.totalQuantity;
      };
    };
  };

  // check how many token id is being sold by a user
  public shared({ caller }) func getUserTokensOnSale(user : T.UID, tokenId : T.TokenId) : async T.TokenAmount {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        return 0;
      };
      case (?info) {
        switch (info.usersxToken.get(user)) {
          case (null) {
            return 0;
          };
          case (?usersxTokenInfo) {
            return usersxTokenInfo.quantity;
          };
        };
      };
    };
  };

  // check price of a token on the market of a user
  public shared({ caller }) func getTokenPrice(tokenId : T.TokenId, user : T.UID) : async T.Price {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        throw Error.reject("Token not found in the market");
      };
      case (?info) {
        switch (info.usersxToken.get(user)) {
          case (null) {
            throw Error.reject("User is not selling this token");
          };
          case (?usersxTokenInfo) {
            return usersxTokenInfo.priceICP;
          };
        };
      };
    };
  };

  // handles reducing token offer from the market
  public shared({ caller }) func takeOffSale(tokenId: T.TokenId, quantity: T.TokenAmount, user: T.UID): async () {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        throw Error.reject("Token not found in the market");
      };
      case(?tokenMarket) {
        switch (tokenMarket.usersxToken.get(user)) {
          case (null){
            throw Error.reject("User's token not found in the market");
          };
          case (?userTokenInfo) {
            let newQuantity: T.TokenAmount = userTokenInfo.quantity - quantity;
            // if the new quantity is 0, remove the user from tokensxuser
            if (newQuantity == 0) {
              await _deleteUserTokenfromMarket(tokenId, user);
              let newTotalQuantity: T.TokenAmount = tokenMarket.totalQuantity - quantity;
              // if the new total quantity is 0, remove the token from the market
              if (newTotalQuantity == 0) {
                  await _deleteTokensInMarket(tokenId);
              } else if (newTotalQuantity > 0) {
                  // Update the total quantity in the market info
                  await _reduceTotalQuantity(tokenId, quantity);
              } else {
                  throw Error.reject("Token quantity cannot be less than 0");
              };
            } else if (newQuantity > 0) {
              // Update the user's token quantity and market info
              await _reduceOffer(tokenId, quantity, user);
              await _reduceTotalQuantity(tokenId, quantity);
            } else {
              throw Error.reject("User's token quantity cannot be less than 0");
            };
          };
        };
      };
    };
  };

  // Function to delete a user's token from the market
  private func _deleteUserTokenfromMarket(tokenId: T.TokenId, user: T.UID): async () {
    switch (tokensInMarket.get(tokenId)) {
      case (null){
        throw Error.reject("Token not found in the market");
      };
      case (?info) {
        switch (info.usersxToken.get(user)) {
          case (null) {
            throw Error.reject("User not found in the market for this token")
          };
          case (?_) {
            info.usersxToken.delete(user);
          };
        };
      };
    };
  };

  // Function to reduce the total quantity of a token in the market
  private func _reduceTotalQuantity(tokenId: T.TokenId, quantity: T.TokenAmount): async () {
    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        throw Error.reject("Token not found in the market");
      };
      case (?info) {
        let newTotalQuantity: Nat = info.totalQuantity - quantity;
        if (newTotalQuantity > 0) {
          let updatedInfo = {
            totalQuantity = Int.abs(newTotalQuantity);
            usersxToken = info.usersxToken;
          };
          tokensInMarket.put(tokenId, updatedInfo);
        } else if (newTotalQuantity == 0) {
          await _deleteTokensInMarket(tokenId);
        } else {
          throw Error.reject("Token quantity cannot be less than 0");
        };
      };
    };
  };

  // Function to reduce the offer of a token in the market
  private func _reduceOffer(tokenId: T.TokenId, quantity: T.TokenAmount, user: T.UID): async () {
    switch (tokensInMarket.get(tokenId)) {
      case (null) {
        throw Error.reject("Token not found in the market");
      };
      case (?info) {
        switch (info.usersxToken.get(user)) {
          case (null) {
            throw Error.reject("User not found in the market for this token");
          };
          case (?userTokenInfo) {
            let newUserQuantity: Nat = userTokenInfo.quantity - quantity;

            if (newUserQuantity > 0) {
              let newUserTokenInfo = { userTokenInfo with quantity = Int.abs(newUserQuantity) };
              info.usersxToken.put(user, newUserTokenInfo);
            } else if (newUserQuantity == 0) {
              await _deleteUserTokenfromMarket(tokenId, user);
            } else {
              throw Error.reject("User's token quantity cannot be less than 0");
            };
          };
        };
      };
    };
  };

  
  private func _getMinMax(hashmap: HM.HashMap<T.UID, T.UserTokenInfo>): (?T.Price, ?T.Price) {
    var min : ?T.Price = null;
    var max : ?T.Price = null;

    for ((_, data) in hashmap.entries()) {
      switch (min) {
        case (null) { min := ?data.priceICP; };
        case (?m) {
          if (data.priceICP.e8s < m.e8s) {
            min := ?data.priceICP;
          };
        };
      };
      switch (max) {
        case (null) { max := ?data.priceICP; };
        case (?m) {
          if (data.priceICP.e8s > m.e8s) {
            max := ?data.priceICP;
          };
        };
      };
    };

    return (min, max);
  };

  // function to get marketplace
  public query func getMarketplace(page: ?Nat, length: ?Nat, priceRange: ?[T.Price]): async {
    data: [{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceICP: T.Price;
      higherPriceICP: T.Price;
    }];
    totalPages: Nat;
  } {
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

    let marketplace = Buffer.Buffer<{
      tokenId: T.TokenId;
      mwh: T.TokenAmount;
      lowerPriceICP: T.Price;
      higherPriceICP: T.Price;
    }>(100);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    for ((currentTokenId, value) in tokensInMarket.entries()) {
      let (min, max) = _getMinMax(value.usersxToken);
      let lowerPriceICP: T.Price = switch(min) {
        case(null) { { e8s = 0 } };
        case(?value) value;
      };
      let higherPriceICP: T.Price = switch(max) {
        case(null) { { e8s = 0 } };
        case(?value) value;
      };

      // filter by tokenId
      let filterRange: Bool = switch(priceRange) {
        case(null) true;
        case(?range) lowerPriceICP.e8s >= range[0].e8s and higherPriceICP.e8s <= range[1].e8s;
      };

      if (i >= startIndex and i < startIndex + maxLength and filterRange) {
        marketplace.add({
          tokenId = currentTokenId;
          mwh = value.totalQuantity;
          lowerPriceICP;
          higherPriceICP;
        });
      };
      i += 1;
    };

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    {
      data = Buffer.toArray<{
        tokenId: T.TokenId;
        mwh: T.TokenAmount;
        lowerPriceICP: T.Price;
        higherPriceICP: T.Price;
      }>(marketplace);
      totalPages;
    }
  };


  // function to get marketplace sellers
  public query func getMarketplaceSellers(page: ?Nat, length: ?Nat, tokenId: ?T.TokenId, priceRange: ?[T.Price], excludedCaller: ?T.UID): async {
    data: [{
      tokenId: T.TokenId;
      userId: T.UID;
      mwh: T.TokenAmount;
      priceICP: T.Price;
    }];
    totalPages: Nat;
  } {
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

    let marketplace = Buffer.Buffer<{
      tokenId: T.TokenId;
      userId: T.UID;
      mwh: T.TokenAmount;
      priceICP: T.Price;
    }>(100);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    for ((currentTokenId, value) in tokensInMarket.entries()) {

      // rule to exclude caller
      let excludeCallerRule = switch(excludedCaller) {
        case(null) true;
        case(?caller) value.usersxToken.get(caller) == null;
      };


      if (i >= startIndex and i < startIndex + maxLength and excludeCallerRule) {

        for((userId, userToken) in value.usersxToken.entries()) {
          switch(tokenId) {

            // return default values
            case(null) {
              marketplace.add({
                userId;
                tokenId = currentTokenId;
                mwh = userToken.quantity;
                priceICP = userToken.priceICP;
              });
            };

            // filter by tokenId
            case(?token) {

              // filter by tokenId
              let filterRange: Bool = switch(priceRange) {
                case(null) true;
                case(?range) userToken.priceICP.e8s >= range[0].e8s and userToken.priceICP.e8s <= range[1].e8s;
              };

              if (currentTokenId == token and filterRange) {
                marketplace.add({
                  userId;
                  tokenId = currentTokenId;
                  mwh = userToken.quantity;
                  priceICP = userToken.priceICP;
                });
              };
            };
          };
        };
      };
      i += 1;
    };

    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    {
      data = Buffer.toArray<{
        tokenId: T.TokenId;
        userId: T.UID;
        mwh: T.TokenAmount;
        priceICP: T.Price;
      }>(marketplace);
      totalPages;
    }
  };


  // Function to delete a token from the market
  private func _deleteTokensInMarket(tokenId: T.TokenId): async () {
    tokensInMarket.delete(tokenId);
  };
};
