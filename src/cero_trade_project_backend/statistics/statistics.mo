import HM "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Array "mo:base/Array";


// canisters
import TokenIndex "canister:token_index";
import Marketplace "canister:marketplace";

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


  // helper function to register asset statistics
  private func _registerAssetStatistic(tokenId: T.TokenId, statistics: { mwh: ?T.TokenAmount; redemptions: ?T.TokenAmount; sells: ?T.TokenAmount; priceTrend: ?T.AssetStatisticPriceTrend; }): async() {
    switch(assetStatistics.get(tokenId)) {
      case(null) {
        let assetInfo = await TokenIndex.getAssetInfo(tokenId);
        let mwh = switch(statistics.mwh) {
          case(null) throw Error.reject("mwh not found");
          case(?value) value;
        };

        assetStatistics.put(tokenId, {
          assetType = assetInfo.deviceDetails.deviceType;
          mwh;
          redemptions = 0;
          sells = 0;
          priceTrend = null;
        });
      };

      case(?{ assetType; mwh = currentMwh; redemptions = currentRedemptions; sells = currentSells; priceTrend = currentPriceTrend }) {
        let mwh = switch(statistics.mwh) {
          case(null) currentMwh;
          case(?value) currentMwh + value;
        };

        let redemptions = switch(statistics.redemptions) {
          case(null) currentRedemptions;
          case(?value) currentRedemptions + value;
        };

        let sells = switch(statistics.sells) {
          case(null) currentSells;
          case(?value) currentSells + value;
        };

        let priceTrend: ?T.AssetStatisticPriceTrend = switch(statistics.priceTrend) {
          case(null) currentPriceTrend;
          case(?valueProvided) {

            switch(currentPriceTrend) {
              case(null) currentPriceTrend;
              case(?value) {
                try {
                  let currentPrice: T.Price = await Marketplace.getTokenPrice(tokenId, value.seller);

                  if (currentPrice.e8s < valueProvided.priceE8S.e8s) { currentPriceTrend } else { ?valueProvided }
                } catch (error) {
                  ?valueProvided
                }
              };
            };
          };
        };

        assetStatistics.put(tokenId, { mwh; assetType; redemptions; sells; priceTrend; });
      };
    };
  };
  
  /// register statistic
  public shared({ caller }) func registerAssetStatistic(tokenId: T.TokenId, { mwh: ?T.TokenAmount; redemptions: ?T.TokenAmount; sells: ?T.TokenAmount; priceTrend: ?T.AssetStatisticPriceTrend; }): async () {
    _callValidation(caller);
    await _registerAssetStatistic(tokenId, { mwh; redemptions; sells; priceTrend; });
  };

  /// register statistics
  public shared({ caller }) func registerAssetStatistics(assets: [{ tokenId: T.TokenId; statistics: { mwh: ?T.TokenAmount; redemptions: ?T.TokenAmount; sells: ?T.TokenAmount; priceTrend: ?T.AssetStatisticPriceTrend; } }]): async () {
    _callValidation(caller);

    for({ tokenId; statistics; } in assets.vals()) {
      await _registerAssetStatistic(tokenId, { mwh = statistics.mwh; redemptions = statistics.redemptions; sells = statistics.sells; priceTrend = statistics.priceTrend; });
    };
  };

  /// reduce mwh on platform statistic
  public shared({ caller }) func reducePlatformMwh(tokenId: T.TokenId, mwh: T.TokenAmount): async () {
    _callValidation(caller);

    switch(assetStatistics.get(tokenId)) {
      case(null) {};

      case(?{ assetType; mwh = currentMwh; redemptions; sells; priceTrend }) {
        assetStatistics.put(tokenId, {
          mwh = currentMwh - mwh;
          assetType;
          redemptions;
          sells;
          priceTrend;
        });
      };
    };
  };

  // get all asset statistics
  public query func getAllAssetStatistics(): async [(T.TokenId, T.AssetStatisticResponse)] {
    Array.map<(T.TokenId, T.AssetStatistic), (T.TokenId, T.AssetStatisticResponse)>(Iter.toArray(assetStatistics.entries()), func (tokenId, statistic) {
      (tokenId, {
        mwh = statistic.mwh;
        assetType = statistic.assetType;
        redemptions = statistic.redemptions;
        sells = statistic.sells;
        priceE8STrend = switch (statistic.priceTrend) {
          case(null) { { e8s = 0 } };
          case(?value) value.priceE8S;
        };
      })
    })
  };

  // get asset statistics
  public query func getAssetStatistics(tokenId: T.TokenId): async T.AssetStatisticResponse {
    switch(assetStatistics.get(tokenId)) {
      case(null) throw Error.reject("token not found");
      case(?{ mwh; assetType; redemptions; sells; priceTrend; }) {
        {
          mwh;
          assetType;
          redemptions;
          sells;
          priceE8STrend = switch (priceTrend) {
            case(null) { { e8s = 0 } };
            case(?value) value.priceE8S;
          };
        };
      }
    };
  };
}
