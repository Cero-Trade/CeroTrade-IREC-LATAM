import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";


// types
import T "../types";

shared({ caller = userIndexCaller }) actor class Users() {
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

  private func _callValidation(caller: Principal) { assert userIndexCaller == caller };

  /// get size of users collection
  public query func length(): async Nat { users.size() };


  /// register user to Cero Trade
  public shared({ caller }) func registerUser(uid: T.UID, token: Text): async() {
    _callValidation(caller);

    let userInfo = {
      vaultToken = token;
      principal = uid;
      companyLogo = null;
      portfolio = [];
      transactions = [];
      beneficiaries = [];
    };

    users.put(uid, userInfo);
  };


  /// delete user to Cero Trade
  public shared({ caller }) func deleteUser(uid: T.UID): async() {
    _callValidation(caller);
    let _ = users.remove(uid)
  };


  /// store user company logo to Cero Trade
  public shared({ caller }) func storeCompanyLogo(uid: T.UID, avatar: T.CompanyLogo): async() {
    _callValidation(caller);

    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) {
        { info with companyLogo = ?avatar }
      };
    };

    users.put(uid, userInfo);
  };


  /// get user from usersAvatar collection
  public shared({ caller }) func getCompanyLogo(uid: T.UID) : async T.CompanyLogo {
    _callValidation(caller);

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
  public shared({ caller }) func updatePortfolio(uid: T.UID, tokenId: T.TokenId, { delete: Bool }) : async() {
    _callValidation(caller);

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
        if (delete) {
          let _ = portfolio.remove(index);
        } else {
          portfolio.put(index, tokenId);
        };

        users.put(uid, { userInfo with portfolio = Buffer.toArray(portfolio) })
      };
    };
  };


  /// delete user portfolio
  public shared({ caller }) func deletePortfolio(uid: T.UID, tokenId: T.TokenId) : async() {
    _callValidation(caller);

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


  /// update user transactions
  public shared({ caller }) func updateTransactions(uid: T.UID, txId: T.TransactionId) : async() {
    _callValidation(caller);

    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let transactions = Buffer.fromArray<T.TransactionId>(userInfo.transactions);

    transactions.add(txId);
    users.put(uid, { userInfo with transactions = Buffer.toArray(transactions) });
  };

  /// update user beneficiaries
  public shared({ caller }) func updateBeneficiaries(uid: T.UID, beneficiaryId: T.BID, { delete: Bool }) : async() {
    _callValidation(caller);

    let userInfo = switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) info;
    };

    let beneficiaries = Buffer.fromArray<T.BID>(userInfo.beneficiaries);

    if (delete) {
      let index = switch(Buffer.indexOf<T.BID>(beneficiaryId, beneficiaries, Principal.equal)) {
        case(null) throw Error.reject("Beneficiary not found");
        case(?value) value;
      };

      let _ = beneficiaries.remove(index);
    } else {
      beneficiaries.add(beneficiaryId);
    };

    users.put(uid, { userInfo with beneficiaries = Buffer.toArray(beneficiaries) });
  };

  public shared({ caller }) func getPortfolioTokenIds(uid: T.UID) : async [T.TokenId] {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.portfolio;
    };
  };

  public shared({ caller }) func getTransactionIds(uid: T.UID) : async [T.TransactionId] {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.transactions;
    };
  };

  public shared({ caller }) func getBeneficiaries(uid: T.UID) : async [T.BID] {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) throw Error.reject(userNotFound);
      case (?info) return info.beneficiaries;
    };
  };

  /// get vaultToken from user
  public shared({ caller }) func getUserToken(uid: T.UID) : async T.UserToken {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken; };
    };
  };

  /// validate current token
  public shared({ caller }) func validateToken(uid: T.UID, token: Text): async Bool {
    _callValidation(caller);

    switch (users.get(uid)) {
      case (null) { throw Error.reject(userNotFound); };
      case (?info) { return info.vaultToken == token; };
    };
  };
}
