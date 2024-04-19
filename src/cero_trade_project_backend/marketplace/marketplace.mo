import Error "mo:base/Error";

import MarketplaceTypes = "./marketplace_types";
import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

// types
import T "../types";

actor Marketplace {

    let tokensInMarket : HM.HashMap<T.TokenId, T.TokenMarketInfo> = HM.HashMap(16, Text.equal, Text.hash);

    // check if token is already on the market
    public func isOnMarket(tokenId : T.TokenId) : async Bool {
        switch (tokensInMarket.get(tokenId)) {
            case (null) { return false };
            case (?_) { return true };
        };
    };

    // check if user is already selling a token
    public func isSellingToken(user : T.UID, tokenId : T.TokenId) : async Bool {
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
    public func newTokensInMarket(tokenId : T.TokenId, user : T.UID, quantity : T.TokenIdQuantity) : async () {
        // user is selling a new token
        let usersxToken = HM.HashMap<T.UID, Nat>(4, Principal.equal, Principal.hash);
        usersxToken.put(user, quantity);

        // update the market info for the token
        let tokenMarketInfo = {
            totalQuantity = quantity;
            usersxToken = usersxToken;
        };

        // add new information to the token market info
        tokensInMarket.put(tokenId, tokenMarketInfo);
    };

    // update token information
    public func updatetokenMarketInfo(user : T.UID, tokenId : T.TokenId, quantity : Nat) : async () {
        switch (tokensInMarket.get(tokenId)) {
            case (null) {
                throw Error.reject("Token not found in the market");
            };
            case (?info) {
                // Update the existing sale
                let previousQuantity = info.usersxToken.get(user);
                // add the new quantity to the existing one
                let newQuantity = switch(previousQuantity) {
                    case(null) { quantity };
                    case(?q) { q + quantity };
                };

                info.usersxToken.put(user, newQuantity);
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

    // handles new token information on market
    public func putOnSale(tokenId : T.TokenId, quantity : T.TokenIdQuantity, user : T.UID) : async () {
        // Check if the user is already selling the token
        let isSelling = await isSellingToken(user, tokenId);
        if (isSelling != false) {
            // update the existing sale
            await updatetokenMarketInfo(user, tokenId, quantity);
        } else {
            // add the new sale
            await newTokensInMarket(tokenId, user, quantity);
        };
    };

    // check how many token id is available for sale
    public func getAvailableTokens(tokenId : T.TokenId) : async Nat {
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
    public func getUserTokensOnSale(user : T.UID, tokenId : T.TokenId) : async Nat {
        switch (tokensInMarket.get(tokenId)) {
            case (null) {
                return 0;
            };
            case (?info) {
                switch (info.usersxToken.get(user)) {
                    case (null) {
                        return 0;
                    };
                    case (?quantity) {
                        return quantity;
                    };
                };
            };
        };
    };

};
