import Principal "mo:base/Principal";

// types
import T "../types"

module UsersInterface {
  public func canister(cid: Principal): Users { actor (Principal.toText(cid)) };

  public type Users = actor {
    length: query () -> async Nat;
    registerUser: (uid: T.UID, token: Text) -> async();
    deleteUser: (uid: T.UID) -> async();
    storeCompanyLogo: (uid: T.UID, avatar: T.CompanyLogo) -> async();
    getCompanyLogo: query (uid: T.UID) -> async T.CompanyLogo;
    updatePortfolio: (uid: T.UID, tokenId: T.TokenId, { delete: Bool }) -> async();
    deletePortfolio: (uid: T.UID, tokenId: T.TokenId) -> async();
    updateTransactions: (uid: T.UID, tx: T.TransactionId) -> async();
    updateBeneficiaries: (uid: T.UID, beneficiaryId: T.BID, { delete: Bool }) -> async();
    getPortfolioTokenIds: query (uid: T.UID) -> async [T.TokenId];
    getTransactionIds: query (uid: T.UID) -> async [T.TransactionId];
    getBeneficiaries: query (uid: T.UID) -> async [T.BID];
    getUserToken: query (uid: T.UID) -> async T.UserToken;
    validateToken: query (uid: T.UID, token: Text) -> async Bool;
  };
}