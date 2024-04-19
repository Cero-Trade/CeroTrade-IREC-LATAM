import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat64 "mo:base/Nat64";
import TM "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import AccountIdentifier "mo:account-identifier";


// types
import T "../types";

actor Users {
  // constants
  stable let userNotFound: Text = "User not found";


  var users: HM.HashMap<T.UID, T.UserInfo> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var usersEntries : [(T.UID, T.UserInfo)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { usersEntries := Iter.toArray(users.entries()) };
  system func postupgrade() {
    users := HM.fromIter<T.UID, T.UserInfo>(usersEntries.vals(), 16, Principal.equal, Principal.hash);
    usersEntries := [];
  };

  /// get size of users collection
  public query func length(): async Nat { users.size() };


  /// register user to cero trade
  public func registerUser(uid: T.UID, token: Text): async() {
    let userInfo = {
      vaultToken = token;
      principal = uid;
      ledger = AccountIdentifier.accountIdentifier(uid, AccountIdentifier.defaultSubaccount());
      companyLogo = null;
      portfolio = [];
      redemptions = [];
      transactions = [];
    };

    users.put(uid, userInfo);
  };


  /// delete user to cero trade
  public func deleteUser(uid: T.UID): async() { let _ = users.remove(uid) };


  /// store user company logo to cero trade
  public func storeCompanyLogo(uid: T.UID, avatar: T.CompanyLogo): async() {
    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) {
        { info with companyLogo = ?avatar }
      };
    };

    users.put(uid, userInfo);
  };


  /// get user from usersAvatar collection
  public query func getCompanyLogo(uid: T.UID) : async T.CompanyLogo {
    let companyLogo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info.companyLogo;
    };

    switch(companyLogo) {
      case(null) throw Error.reject("Logo not found");
      case(?value) value;
    }
  };


  /// update user portfolio
  public func updatePorfolio(uid: T.UID, tokenId: T.TokenId) : async() {
    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let portfolio = Buffer.fromArray<T.TokenId>(userInfo.portfolio);

    switch(Buffer.indexOf<T.TokenId>(tokenId, portfolio, Text.equal)) {
      case(null) {
        portfolio.add(tokenId);

        users.put(uid, { userInfo with portfolio = Buffer.toArray(portfolio) })
      };
      case(?index) {
        portfolio.put(index, tokenId);

        users.put(uid, { userInfo with portfolio = Buffer.toArray(portfolio) })
      };
    };
  };


  /// delete user portfolio
  public func deletePorfolio(uid: T.UID, tokenId: T.TokenId) : async() {
    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let portfolio = Buffer.fromArray<T.TokenId>(userInfo.portfolio);

    switch(Buffer.indexOf<T.TokenId>(tokenId, portfolio, Text.equal)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?index) {
        let _ = portfolio.remove(index);

        users.put(uid, { userInfo with portfolio = Buffer.toArray(portfolio) })
      };
    };
  };


  /// update user redemptions
  public func updateRedemptions(uid: T.UID, redemId: T.RedemId) : async() {
    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let redemptions = Buffer.fromArray<T.RedemId>(userInfo.redemptions);

    switch(Buffer.indexOf<T.RedemId>(redemId, redemptions, Nat.equal)) {
      case(null) {
        redemptions.add(redemId);

        users.put(uid, { userInfo with redemptions = Buffer.toArray(redemptions) })
      };
      case(?index) {
        redemptions.put(index, redemId);

        users.put(uid, { userInfo with redemptions = Buffer.toArray(redemptions) })
      };
    };
  };


  /// delete user redemption
  public func deleteRedemption(uid: T.UID, redemId: T.RedemId) : async() {
    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let redemptions = Buffer.fromArray<T.RedemId>(userInfo.redemptions);

    switch(Buffer.indexOf<T.RedemId>(redemId, redemptions, Nat.equal)) {
      case(null) throw Error.reject("Redemption doesn't exists");
      case(?index) {
        let _ = redemptions.remove(index);

        users.put(uid, { userInfo with redemptions = Buffer.toArray(redemptions) })
      };
    };
  };


  /// update user transactions
  public func updateTransactions(uid: T.UID, txId: T.TransactionId) : async() {
    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let transactions = Buffer.fromArray<T.TransactionId>(userInfo.transactions);

    switch(Buffer.indexOf<T.TransactionId>(txId, transactions, Nat.equal)) {
      case(null) {
        transactions.add(txId);

        users.put(uid, { userInfo with transactions = Buffer.toArray(transactions) })
      };
      case(?index) {
        transactions.put(index, txId);

        users.put(uid, { userInfo with transactions = Buffer.toArray(transactions) })
      };
    };
  };


  public query func getPortfolioTokenIds(uid: T.UID) : async [T.TokenId] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.portfolio;
    };
  };

  public query func getRedemptions(uid: T.UID) : async [T.RedemId] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.redemptions;
    };
  };

  public query func getTransactions(uid: T.UID) : async [T.TransactionId] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.transactions;
    };
  };

  /// get vaultToken from user
  public query func getUserToken(uid: T.UID) : async Text {
    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken; };
    };
  };

  /// validate current token
  public query func validateToken(uid: T.UID, token: Text): async Bool {
    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken == token; };
    };
  };
}
