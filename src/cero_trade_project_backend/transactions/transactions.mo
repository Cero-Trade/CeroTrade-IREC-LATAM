import HM "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat64 "mo:base/Nat64";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";


// types
import T "../types";
import ENV "../env";

actor Transactions {
  // constants
  stable let notFound: Text = "Transaction not found";


  var transactions: HM.HashMap<T.TransactionId, T.TransactionInfo> = HM.HashMap(16, Text.equal, Text.hash);
  stable var transactionsEntries : [(T.TransactionId, T.TransactionInfo)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { transactionsEntries := Iter.toArray(transactions.entries()) };
  system func postupgrade() {
    transactions := HM.fromIter<T.TransactionId, T.TransactionInfo>(transactionsEntries.vals(), 16, Text.equal, Text.hash);
    transactionsEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.TRANSACTION_INDEX_CANISTER_ID) == caller };

  /// get size of transactions collection
  public query func length(): async Nat { transactions.size() };


  /// register transaction to cero trade
  public shared({ caller }) func registerTransaction(txInfo: T.TransactionInfo): async T.TransactionId {
    _callValidation(caller);

    let txId = Nat.toText(transactions.size() + 1);
    let tx = { txInfo with transactionId = txId };

    transactions.put(txId, tx);
    txId
  };

  public shared({ caller }) func getRedemptions(txIds: [T.TransactionId]): async [T.TransactionInfo] {
    _callValidation(caller);

    let txs = Buffer.Buffer<T.TransactionInfo>(100);

    for(tx in txIds.vals()) {
      switch(transactions.get(tx)) {
        case(null) {};
        case(?txInfo) txs.add(txInfo);
      };
    };

    Buffer.toArray<T.TransactionInfo>(txs);
  };
}
