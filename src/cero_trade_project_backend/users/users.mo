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
import Debug "mo:base/Debug";


// types
import T "../types";

actor class Users() = this {
  stable let userNotFound: Text = "User not found";

  let users: HM.HashMap<T.UID, T.UserInfo> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of users collection
  public query func length(): async Nat { users.size() };


  /// register user to cero trade
  public func registerUser(uid: T.UID, token: Text): async T.CanisterId {
    let userInfo = {
      vaultToken = token;
      principal = uid;
      ledger = AccountIdentifier.accountIdentifier(uid, AccountIdentifier.defaultSubaccount());
      companyLogo = null;
      portfolio = [];
      redemptions = TM.TrieMap<T.RedemId, T.RedemInfo>(Nat.equal, Hash.hash);
      transactions = TM.TrieMap<T.TransactionId, T.TransactionInfo>(Nat.equal, Hash.hash);
    };

    users.put(uid, userInfo);

    Principal.fromActor(this)
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
  public func updateRedemptions(uid: T.UID, redem: T.RedemInfo) : async() {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info.redemptions.put(redem.redemId, redem);
    };
  };


  /// update user transactions
  public func updateTransactions(uid: T.UID, tx: T.TransactionInfo) : async() {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info.transactions.put(tx.transactionId, tx);
    };
  };



  public query func getPortfolioTokenIds(uid: T.UID) : async [T.TokenId] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.portfolio;
    };
  };

  public query func getRedemptions(uid: T.UID) : async [T.RedemInfo] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return Iter.toArray<T.RedemInfo>(info.redemptions.vals());
    };
  };

  public query func getTransactions(uid: T.UID) : async [T.TransactionInfo] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return Iter.toArray<T.TransactionInfo>(info.transactions.vals());
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
