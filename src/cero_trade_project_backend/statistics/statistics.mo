import HM "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Error "mo:base/Error";


// canisters
import TokenIndex "canister:token_index";

// types
import T "../types";
import ENV "../env";

shared({ caller = owner }) actor class Statistics() {
  var assetStatistics: HM.HashMap<T.TokenId, T.AssetStatistic> = HM.HashMap(16, Text.equal, Text.hash);
  stable var assetStatisticsEntries : [(T.TokenId, T.AssetStatistic)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { assetStatisticsEntries := Iter.toArray(assetStatistics.entries()) };
  system func postupgrade() {
    assetStatistics := HM.fromIter<T.TokenId, T.AssetStatistic>(assetStatisticsEntries.vals(), 16, Text.equal, Text.hash);
    assetStatisticsEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };


  /// register statistic
  public shared({ caller }) func registerAssetStatistic(tokenId: T.TokenId, statistics: { mwh: ?T.TokenAmount; redemptions: ?T.TokenAmount }): async () {
    _callValidation(caller);

    switch(assetStatistics.get(tokenId)) {
      case(null) {
        let assetInfo = await TokenIndex.getAssetInfo(tokenId);
        let mwh = switch(statistics.mwh) {
          case(null) throw Error.reject("mwh not found");
          case(?value) value;
        };

        assetStatistics.put(tokenId, {
          assetType = assetInfo.assetType;
          mwh;
          redemptions = 0;
        });
      };

      case(?{ assetType; mwh = currentMwh; redemptions = currentRedemptions; }) {
        let mwh = switch(statistics.mwh) {
          case(null) 0;
          case(?value) value;
        };
        let redemptions = switch(statistics.redemptions) {
          case(null) 0;
          case(?value) value;
        };

        assetStatistics.put(tokenId, {
          mwh = currentMwh + mwh;
          assetType;
          redemptions = currentRedemptions + redemptions;
        });
      };
    };
  };

  // get all asset statistics
  public query func getAllAssetStatistics(): async [(T.TokenId, T.AssetStatistic)] { Iter.toArray(assetStatistics.entries()) };

  // get asset statistics
  public query func getAssetStatistics(tokenId: T.TokenId): async T.AssetStatistic {
    switch(assetStatistics.get(tokenId)) {
      case(null) throw Error.reject("token not found");
      case(?value) value;
    };
  };
}
