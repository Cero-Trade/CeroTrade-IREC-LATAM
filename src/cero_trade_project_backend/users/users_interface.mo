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
    updatePorfolio: (uid: T.UID, tokenId: T.TokenId, delete: Bool) -> async();
    deletePorfolio: (uid: T.UID, tokenId: T.TokenId) -> async();
    updateTransactions: (uid: T.UID, tx: T.TransactionId) -> async();
    getPortfolioTokenIds: query (uid: T.UID) -> async [T.TokenId];
    getTransactionIds: query (uid: T.UID) -> async [T.TransactionId];
    getBeneficiaries: query (uid: T.UID) -> async [T.Beneficiary];
    getUserToken: query (uid: T.UID) -> async Text;
    validateToken: query (uid: T.UID, token: Text) -> async Bool;
  };
}