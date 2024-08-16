import Principal "mo:base/Principal";

// types
import T "../types"

module TransactionsInterface {
  public func canister(cid: Principal): Transactions { actor (Principal.toText(cid)) };

  public type Transactions = actor {
    length: query () -> async Nat;
    registerTransaction: (tx: T.TransactionInfo) -> async T.TransactionId;
    getTransactionsById: query (txIds: [T.TransactionId], txType: ?T.TxType, priceRange: ?[T.Price], mwhRange: ?[T.TokenAmount], method: ?T.TxMethod, rangeDates: ?[Text], tokenId: ?T.TokenId) -> async [T.TransactionInfo];
  };
}