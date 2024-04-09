import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
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
import Serde "mo:serde";

// canisters
import HttpService "canister:http_service";

// types
import T "../types";
import HT "../http_service/http_service_types";

actor class Users() = this {
  stable let userNotFound: Text = "User not found";

  let users: HM.HashMap<T.UID, T.UserInfo> = HM.HashMap(16, Principal.equal, Principal.hash);


  /// get size of users collection
  public query func length(): async Nat { users.size() };


  /// validate user existence
  public query func checkPrincipal(uid: T.UID) : async Bool {
    switch(users.get(uid)) {
      case(null) false;
      case(?value) true;
    };
  };

  /// register user to cero trade
  public func registerUser(uid: T.UID, token: Text): async T.CanisterId {
    let userInfo = {
      vaultToken = token;
      principal = uid;
      ledger = AccountIdentifier.accountIdentifier(uid, AccountIdentifier.defaultSubaccount());
      companyLogo = null;
      portfolio = HM.HashMap<T.TokenId, T.TokenInfo>(1, Text.equal, Text.hash);
      redemptions = TM.TrieMap<T.RedemId, T.RedemInfo>(Nat.equal, Hash.hash);
      transactions = TM.TrieMap<T.TransactionId, T.TransactionInfo>(Nat.equal, Hash.hash);
    };

    users.put(uid, userInfo);

    Principal.fromActor(this)
  };


  /// register user to cero trade
  public func deleteUser(uid: T.UID): async() {
    let token = switch(users.get(uid)) {
      case(null) throw Error.reject(userNotFound);
      case(?user) user.vaultToken;
    };

    let formData = { token };
    let formBlob = to_candid(formData);
    let formKeys = ["token"];

    let res = await HttpService.post(HT.apiUrl # "users/delete", {
        headers = [];
        bodyJson = switch(Serde.JSON.toText(formBlob, formKeys, null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });

    let removedUser = users.remove(uid);
  };


  /// store user company logo to cero trade
  public func storeCompanyLogo(uid: T.UID, avatar: Blob): async() {
    var userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) {
        { info with companyLogo = ?avatar }
      };
    };

    users.put(uid, userInfo);
  };


  /// get user from usersAvatar collection
  public query func getCompanyLogo(uid: T.UID) : async Blob {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) switch(info.companyLogo) {
        case(null) throw Error.reject("Logo not found");
        case(?value) value;
      };
    };
  };


  /// update user portfolio
  public func updatePorfolio(uid: T.UID, token: T.TokenInfo) : async() {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info.portfolio.put(token.tokenId, token);
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



  public query func getPortfolio(uid: T.UID) : async [T.TokenInfo] {
    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return Iter.toArray<T.TokenInfo>(info.portfolio.vals());
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
