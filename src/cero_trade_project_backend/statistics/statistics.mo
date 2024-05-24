import HM "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";


// types
import T "../types";
import ENV "../env";

shared({ caller = owner }) actor class Statistics() {
  var assetStatistics: HM.HashMap<Text, T.TokenAmount> = HM.HashMap(16, Text.equal, Text.hash);
  stable var assetStatisticsEntries : [(Text, T.TokenAmount)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { assetStatisticsEntries := Iter.toArray(assetStatistics.entries()) };
  system func postupgrade() {
    assetStatistics := HM.fromIter<Text, T.TokenAmount>(assetStatisticsEntries.vals(), 16, Text.equal, Text.hash);
    assetStatisticsEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };


  /// register statistic
  public shared({ caller }) func registerAssetStatistic(assetType: T.AssetType, mwh: T.TokenAmount): async () {
    _callValidation(caller);

    let energy: Text = switch(assetType) {
      case(#hydro(hydro)) hydro;
      case(#ocean(ocean)) ocean;
      case(#geothermal(geothermal)) geothermal;
      case(#biome(biome)) biome;
      case(#wind(wind)) wind;
      case(#sun(sun)) sun;
      case(#other(other)) other;
    };

    switch(assetStatistics.get(energy)) {
      case(null) assetStatistics.put(energy, mwh);
      case(?currentMwhs) assetStatistics.put(energy, currentMwhs + mwh);
    };
  };

  // get asset registrations
  public query func getAssetStatistics(): async [(Text, T.TokenAmount)] { Iter.toArray(assetStatistics.entries()) };
}
