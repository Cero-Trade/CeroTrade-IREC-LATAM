import HM "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import DateTime "mo:datetime/DateTime";


// types
import T "../types";

shared({ caller = transactionIndexCaller }) actor class Transactions() {
  var transactions: HM.HashMap<T.TransactionId, T.TransactionInfo> = HM.HashMap(50, Text.equal, Text.hash);
  stable var transactionsEntries : [(T.TransactionId, T.TransactionInfo)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { transactionsEntries := Iter.toArray(transactions.entries()) };
  system func postupgrade() {
    transactions := HM.fromIter<T.TransactionId, T.TransactionInfo>(transactionsEntries.vals(), 50, Text.equal, Text.hash);
    transactionsEntries := [];
  };

  private func _callValidation(caller: Principal) { assert transactionIndexCaller == caller };

  /// get size of transactions collection
  public query func length(): async Nat { transactions.size() };


  /// register transaction to Cero Trade
  public shared({ caller }) func registerTransaction(txInfo: T.TransactionInfo): async T.TransactionId {
    _callValidation(caller);

    transactions.put(txInfo.transactionId, txInfo);
    txInfo.transactionId
  };


  public query func getTransactionsById(txIds: [T.TransactionId], txType: ?T.TxType, priceRange: ?[T.Price], mwhRange: ?[T.TokenAmount], method: ?T.TxMethod, rangeDates: ?[Text], tokenId: ?T.TokenId): async [T.TransactionInfo] {
    let txs = Buffer.Buffer<T.TransactionInfo>(50);

    for(tx in txIds.vals()) {
      switch(transactions.get(tx)) {
        case(null) {};

        case(?txInfo) {
          // filter by mwhRange
          let filterRange: Bool = switch(mwhRange) {
            case(null) true;
            case(?range) txInfo.tokenAmount >= range[0] and txInfo.tokenAmount <= range[1];
          };

          // filter priceRange
          let filterPrice: Bool = switch(priceRange) {
            case(null) true;
            case(?range) {
              switch(txInfo.priceE8S) {
                case(null) true;
                case(?priceE8S) priceE8S.e8s >= range[0].e8s and priceE8S.e8s <= range[1].e8s;
              };
            };
          };

          // filter by txType
          let filterType: Bool = switch(txType) {
            case(null) true;
            case(?typeTx) txInfo.txType == typeTx;
          };

          // filter by method
          let filterMethod: Bool = switch(method) {
            case(null) true;
            case(?value) txInfo.method == value;
          };

          // filter by dates
          let filterDates: Bool = switch(rangeDates) {
            case(null) true;
            case(?dates) {
              let txDate = switch(DateTime.fromText(txInfo.date, T.dateFormat)) {
                case(null) throw Error.reject("Failed to parse datetime");
                case(?dateTime) dateTime;
              };

              let compareFrom = switch(DateTime.fromText(dates[0], T.dateFormat)) {
                case(null) throw Error.reject("Failed to parse datetime");
                case(?dateTime) dateTime.compare(txDate) == #equal or dateTime.compare(txDate) == #less;
              };

              let compareTo = switch(DateTime.fromText(dates[1], T.dateFormat)) {
                case(null) throw Error.reject("Failed to parse datetime");
                case(?dateTime) dateTime.compare(txDate) == #equal or dateTime.compare(txDate) == #greater;
              };

              compareFrom and compareTo
            };
          };

          // filter by tokenId
          let filterTokenId: Bool = switch(tokenId) {
            case(null) true;
            case(?value) txInfo.tokenId == value;
          };

          if (filterType and filterPrice and filterRange and filterMethod and filterDates and filterTokenId) txs.add(txInfo)
        };
      };
    };

    Buffer.toArray<T.TransactionInfo>(txs);
  };

  public query func getOutTransactionsById(txIds: [T.TransactionId], mwhRange: ?[T.TokenAmount], rangeDates: ?[Text], tokenId: ?T.TokenId): async [T.TransactionInfo] {
    let txs = Buffer.Buffer<T.TransactionInfo>(50);

    for(tx in txIds.vals()) {
      switch(transactions.get(tx)) {
        case(null) {};

        case(?txInfo) {
          // filter by mwhRange
          let filterRange: Bool = switch(mwhRange) {
            case(null) true;
            case(?range) txInfo.tokenAmount >= range[0] and txInfo.tokenAmount <= range[1];
          };

          // filter by txType
          let filterType: Bool = switch(txInfo.txType) {
            case(#purchase("purchase")) true;
            case(#redemption("redemption")) true;
            case(#mint("mint")) true;
            case(_) false;
          };

          // filter by dates
          let filterDates: Bool = switch(rangeDates) {
            case(null) true;
            case(?dates) {
              let txDate = switch(DateTime.fromText(txInfo.date, T.dateFormat)) {
                case(null) throw Error.reject("Failed to parse datetime");
                case(?dateTime) dateTime;
              };

              let compareFrom = switch(DateTime.fromText(dates[0], T.dateFormat)) {
                case(null) throw Error.reject("Failed to parse datetime");
                case(?dateTime) dateTime.compare(txDate) == #equal or dateTime.compare(txDate) == #less;
              };

              let compareTo = switch(DateTime.fromText(dates[1], T.dateFormat)) {
                case(null) throw Error.reject("Failed to parse datetime");
                case(?dateTime) dateTime.compare(txDate) == #equal or dateTime.compare(txDate) == #greater;
              };

              compareFrom and compareTo
            };
          };

          // filter by tokenId
          let filterTokenId: Bool = switch(tokenId) {
            case(null) true;
            case(?value) txInfo.tokenId == value;
          };

          if (filterType and filterRange and filterDates and filterTokenId) txs.add(txInfo)
        };
      };
    };

    Buffer.toArray<T.TransactionInfo>(txs);
  };
}
