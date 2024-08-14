import Error "mo:base/Error";
import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

// types
import T "../types";
import ENV "../env";

actor class Marketplace() = this {

  var tokensInMarket : HM.HashMap<T.TokenId, T.TokenMarketInfo> = HM.HashMap(50, Text.equal, Text.hash);
  stable var tokensInMarketEntries : [(T.TokenId, T.TokenAmount, [(T.UID, T.UserTokenInfo)])] = [];

  /// funcs to persistent collection state
  system func preupgrade() {
    let marketplace = Buffer.Buffer<(T.TokenId, T.TokenAmount, [(T.UID, T.UserTokenInfo)])>(50);

    for ((tokenId, tokenMarketInfo) in tokensInMarket.entries()) {
      let usersxToken = Buffer.Buffer<((T.UID, T.UserTokenInfo))>(50);

      for ((userId, userTokenInfo) in tokenMarketInfo.usersxToken.entries()) {
        usersxToken.add( (userId, userTokenInfo) )
      };

      marketplace.add( (tokenId, tokenMarketInfo.totalQuantity, Buffer.toArray<(T.UID, T.UserTokenInfo)>(usersxToken)) );
    };

    tokensInMarketEntries := Buffer.toArray<(T.TokenId, T.TokenAmount, [(T.UID, T.UserTokenInfo)])>(marketplace)
  };

  system func postupgrade() {
    for ((tokenId, totalQuantity, users) in tokensInMarketEntries.vals()) {
      var usersxToken = HM.HashMap<T.UID, T.UserTokenInfo>(100, Principal.equal, Principal.hash);

      for ((userId, userTokenInfo) in users.vals()) {
        usersxToken.put(userId, userTokenInfo);
      };

      tokensInMarket.put(tokenId, { totalQuantity; usersxToken });
    };
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller or Principal.fromActor(this) == caller };



  // check if token is already on the market
  public shared({ caller }) func isOnMarket(tokenId : T.TokenId) : async Bool {
    _callValidation(caller);

    switch (tokensInMarket.get(tokenId)) {
      case (null) { return false };
      case (?_) { return true };
    };
  };

  // TODO troubles here setting token on marketplace
  // handles new token information on market
  public shared({ caller }) func putOnSale(tokenId : T.TokenId, quantity : T.TokenAmount, user : T.UID, priceE8S: T.Price) : async () {
    _callValidation(caller);

    switch(tokensInMarket.get(tokenId)) {
      // token doesnt exists
      case(null) {
        let usersxToken = HM.HashMap<T.UID, T.UserTokenInfo>(100, Principal.equal, Principal.hash);
        usersxToken.put(user, { quantity; priceE8S });
        tokensInMarket.put(tokenId, { totalQuantity = quantity; usersxToken; });
      };

      // token exists
      case(?tokenMarketInfo) {
        let usersxToken = tokenMarketInfo.usersxToken;
        usersxToken.put(user, { quantity; priceE8S });

        tokensInMarket.put(tokenId, {
          tokenMarketInfo with totalQuantity = tokenMarketInfo.totalQuantity + quantity;
          usersxToken
        });
      };
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

  // check if user is already selling a token
  public query func isSellingToken(user : T.UID, tokenId : T.TokenId): async Bool {
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
            return usersxTokenInfo.priceE8S;
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
        case (null) { min := ?data.priceE8S; };
        case (?m) {
          if (data.priceE8S.e8s < m.e8s) {
            min := ?data.priceE8S;
          };
        };
      };
      switch (max) {
        case (null) { max := ?data.priceE8S; };
        case (?m) {
          if (data.priceE8S.e8s > m.e8s) {
            max := ?data.priceE8S;
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
      lowerPriceE8S: T.Price;
      higherPriceE8S: T.Price;
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
      lowerPriceE8S: T.Price;
      higherPriceE8S: T.Price;
    }>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    for ((currentTokenId, tokenMarketInfo) in tokensInMarket.entries()) {
      let (min, max) = _getMinMax(tokenMarketInfo.usersxToken);
      let lowerPriceE8S: T.Price = switch(min) {
        case(null) { { e8s = 0 } };
        case(?minPrice) minPrice;
      };
      let higherPriceE8S: T.Price = switch(max) {
        case(null) { { e8s = 0 } };
        case(?maxPrice) maxPrice;
      };

      // filter by tokenId
      let filterRange: Bool = switch(priceRange) {
        case(null) true;
        case(?range) lowerPriceE8S.e8s >= range[0].e8s and higherPriceE8S.e8s <= range[1].e8s;
      };

      if (i >= startIndex and i < startIndex + maxLength and filterRange) {
        marketplace.add({
          tokenId = currentTokenId;
          mwh = tokenMarketInfo.totalQuantity;
          lowerPriceE8S;
          higherPriceE8S;
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
        lowerPriceE8S: T.Price;
        higherPriceE8S: T.Price;
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
      priceE8S: T.Price;
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
      priceE8S: T.Price;
    }>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    for ((currentTokenId, tokenMarketInfo) in tokensInMarket.entries()) {

      if (i >= startIndex and i < startIndex + maxLength) {

        for((userId, userToken) in tokenMarketInfo.usersxToken.entries()) {
          // rule to exclude caller
          let excludeCallerRule: Bool = switch(excludedCaller) {
            case(null) true;
            case(?caller) userId != caller;
          };

          // filter by tokenId
          let filterTokenId: Bool = switch(tokenId) {
            case(null) true;
            case(?token) currentTokenId == token;
          };

          // filter by filterRange
          let filterRange: Bool = switch(priceRange) {
            case(null) true;
            case(?range) userToken.priceE8S.e8s >= range[0].e8s and userToken.priceE8S.e8s <= range[1].e8s;
          };

          if (filterTokenId and filterRange and excludeCallerRule) {
            marketplace.add({
              userId;
              tokenId = currentTokenId;
              mwh = userToken.quantity;
              priceE8S = userToken.priceE8S;
            });
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
        priceE8S: T.Price;
      }>(marketplace);
      totalPages;
    }
  };


  // Function to delete a token from the market
  private func _deleteTokensInMarket(tokenId: T.TokenId): async () {
    tokensInMarket.delete(tokenId);
  };
};
