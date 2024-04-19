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

  /// get size of transactions collection
  public query func length(): async Nat { transactions.size() };


  /// register user to cero trade
  public func registerTransaction(txId: T.TransactionId, tx: T.TransactionInfo): async() {
    transactions.put(txId, tx);
  };
}
