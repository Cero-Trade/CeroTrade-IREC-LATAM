import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import Types "./users_types";
import Error "mo:base/Error";


actor Users {

    let userTokenMap = TrieMap.TrieMap<Principal, Types.UserInfo>(Principal.equal, Principal.hash);

    public func getTokensByUser(userPrincipal: Principal): async ?Types.TokenList {
    // Use TrieMap.get to attempt to retrieve the UserInfo for the provided principal
    let maybeUserInfo = TrieMap.get(userDirectory, userPrincipal);
    switch (maybeUserInfo) {
        // If no user is found, return null
        case (null) { return null; };
        // If user is found, return their list of tokens
        case (?userInfo) { return userInfo.tokens; };
    };
};

};