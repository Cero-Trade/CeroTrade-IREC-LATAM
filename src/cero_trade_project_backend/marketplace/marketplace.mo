import Error "mo:base/Error";

import MarketplaceTypes = "./marketplace_types";
import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Int "mo:base/Int";

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

    // handles reducing token offer from the market
    public func takeOffSale(tokenId: T.TokenId, quantity: T.TokenIdQuantity, user: T.UID): async () {

        switch (tokensInMarket.get(tokenId)) {
            case (null) {
                throw Error.reject("Token not found in the market");
            };
            case(?tokenMarket) {
                switch (tokenMarket.usersxToken.get(user)) {
                    case (null){
                        throw Error.reject("User's token not found in the market");
                    };
                    case (?userQuantity) {
                        let newQuantity = Float.fromInt(userQuantity) - Float.fromInt(quantity);
                        // if the new quantity is 0, remove the user from tokensxuser
                        if (newQuantity == 0) {
                            await deleteUserTokenfromMarket(tokenId, user);
                            let newTotalQuantity = Float.fromInt(tokenMarket.totalQuantity) - Float.fromInt(quantity);
                            // if the new total quantity is 0, remove the token from the market
                            if (newTotalQuantity == 0) {
                                await deleteTokensInMarket(tokenId);
                            } else if (newTotalQuantity > 0) {
                                // Update the total quantity in the market info
                                await reduceTotalQuantity(tokenId, quantity);
                            } else {
                                throw Error.reject("Token quantity cannot be less than 0");
                            };
                        } else if (newQuantity > 0) {
                            // Update the user's token quantity and market info
                            await reduceOffer(tokenId, quantity, user);
                            await reduceTotalQuantity(tokenId, quantity);
                        } else {
                            throw Error.reject("User's token quantity cannot be less than 0");
                        };
                    };
                };
            };
        };
    };

    // Function to delete a user's token from the market
    public func deleteUserTokenfromMarket(tokenId: T.TokenId, user: T.UID): async () {
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
    public func reduceTotalQuantity(tokenId: T.TokenId, quantity: T.TokenIdQuantity): async () {
        switch (tokensInMarket.get(tokenId)) {
            case (null) {
                throw Error.reject("Token not found in the market");
            };
            case (?info) {
                let newTotalQuantity = info.totalQuantity - quantity;
                if (newTotalQuantity > 0) {
                    let updatedInfo = {
                        totalQuantity = Int.abs(newTotalQuantity);
                        usersxToken = info.usersxToken;
                    };
                    tokensInMarket.put(tokenId, updatedInfo);
                } else if (newTotalQuantity == 0) {
                    await deleteTokensInMarket(tokenId);
                } else {
                    throw Error.reject("Token quantity cannot be less than 0");
                };
            };
        };
    };

    // Function to reduce the offer of a token in the market
    public func reduceOffer(tokenId: T.TokenId, quantity: T.TokenIdQuantity, user: T.UID): async () {
        switch (tokensInMarket.get(tokenId)) {
            case (null) {
                throw Error.reject("Token not found in the market");
            };
            case (?info) {
                switch (info.usersxToken.get(user)) {
                    case (null) {
                        throw Error.reject("User not found in the market for this token");
                    };
                    case (?userQuantity) {
                        let newUserQuantity = userQuantity - quantity;
                        if (newUserQuantity > 0) {
                            info.usersxToken.put(user, Int.abs(newUserQuantity));
                        } else if (newUserQuantity == 0) {
                            await deleteUserTokenfromMarket(tokenId, user);
                        } else {
                            throw Error.reject("User's token quantity cannot be less than 0");
                        };
                    };
                };
            };
        };
    };

    // Function to delete a token from the market
    public func deleteTokensInMarket(tokenId: T.TokenId): async () {
        tokensInMarket.delete(tokenId);
    };

};
