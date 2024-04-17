import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";

// canisters
import HttpService "canister:http_service";

// types
import T "../types";
import HT "../http_service/http_service_types";

actor class TokenIndex() = this {
  stable let ic : T.IC = actor ("aaaaa-aa");
  private func TokenCanister(cid: T.CanisterId): T.TokenInterface { actor (Principal.toText(cid)) };
  stable var wasm_array : [Nat] = [];


  let tokenDirectory: HM.HashMap<Text, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);


  /// get size of tokenDirectory collection
  public query func length(): async Nat { tokenDirectory.size() };


  // TODO validate user authenticate to only admin
  public func registerWasmArray(uid: T.UID, array: [Nat]): async [Nat] {
    wasm_array := array;
    wasm_array
  };

  /// register [tokenDirectory] collection
  public shared({ caller }) func registerToken(tokenId: Text): async Principal {
    if (tokenId == "") throw Error.reject("Must to provide a tokenId");

    switch(tokenDirectory.get(tokenId)) {
      case(?value) throw Error.reject("Token already exists");
      case(null) {
        Debug.print(debug_show ("before registerToken: " # Nat.toText(Cycles.balance())));

        Cycles.add(300_000_000_000);
        let { canister_id } = await ic.create_canister({
          settings = ?{
            controllers = ?[Principal.fromActor(this), caller];
            compute_allocation = null;
            memory_allocation = null;
            freezing_threshold = null;
          }
        });

        Debug.print(debug_show ("later create_canister: " # Nat.toText(Cycles.balance())));

        try {
          let nums8 : [Nat8] = Array.map<Nat, Nat8>(wasm_array, Nat8.fromNat);

          await ic.install_code({
            arg = to_candid(tokenId);
            wasm_module = Blob.fromArray(nums8);
            mode = #install;
            canister_id;
          });

          Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

          // TODO perfome data fetch asset info using [tokenId] here
          let energy = switch(tokenId) {
            case("1") #hydro("hydro");
            case("2") #ocean("ocean");
            case("3") #geothermal("geothermal");
            case("4") #biome("biome");
            case("5") #wind("wind");
            case("6") #sun("sun");
            case _ #other("other");
          };

          let assetMetadata: T.AssetInfo = /* await HttpService.get("getToken" # tokenId, { headers = [] }) */
            {
              assetType = energy;
              startDate: Nat64 = 12345678901234567890;
              endDate: Nat64 = 18446744073709551615;
              co2Emission: Float = 11.22;
              radioactivityEmnission: Float = 10.20;
              volumeProduced: Float = 1000;
              deviceDetails = {
                name = "machine";
                deviceType = "type";
                group = energy;
                description = "description";
              };
              specifications = {
                deviceCode = "200";
                capacity: Float = 1000;
                location = "location";
                latitude: Float = 0;
                longitude: Float = 1;
                address = "address anywhere";
                stateProvince = "chile";
                country = "chile";
              };
              dates: [Nat64] = [123321, 123123];
            };

          await TokenCanister(canister_id).init(assetMetadata);

          tokenDirectory.put(tokenId, canister_id);
          return canister_id
        } catch (error) {
          await ic.stop_canister({ canister_id });
          await ic.delete_canister({ canister_id });
          throw Error.reject(Error.message(error));
        }
      };
    };
  };

  /// delete [tokenDirectory] collection
  public func deleteToken(tokenId: Text): async () {
    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add(20_949_972_000);
        await ic.stop_canister({ canister_id });
        await ic.delete_canister({ canister_id });
        let _ = tokenDirectory.remove(tokenId)
      };
    }
  };

  /// manage token status
  public func tokenStatus(tokenId: T.TokenId): async {
    status: { #stopped; #stopping; #running };
    memory_size: Nat;
    cycles: Nat;
    settings: T.CanisterSettings;
    idle_cycles_burned_per_day: Nat;
    module_hash: ?[Nat8];
  } {
    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add(20_949_972_000);
        return await ic.canister_status({ canister_id });
      };
    };
  };

  /// resume token status
  public func startToken(tokenId: T.TokenId): async () {
    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add(20_949_972_000);
        await ic.start_canister({ canister_id });
      };
    };
  };

  /// stop token status
  public func stopToken(tokenId: T.TokenId): async () {
    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add(20_949_972_000);
        await ic.stop_canister({ canister_id });
      };
    };
  };

  /// get canister id that allow current user
  public query func getTokenCanister(tokenId: T.TokenId): async T.CanisterId {
    switch (tokenDirectory.get(tokenId)) {
      case (null) { throw Error.reject("Token not found"); };
      case (?cid) { return cid };
    };
  };



  public func getRemainingAmount(tokenId: T.TokenId): async Float {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) return await TokenCanister(cid).getRemainingAmount();
    };
  };

  public func getAssetInfo(tokenId: T.TokenId): async T.AssetInfo {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) return await TokenCanister(cid).getAssetInfo();
    };
  };

  public func mintToken(uid: T.UID, tokenId: T.TokenId, amount: Float): async() {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).mintToken(uid, amount);
    };
  };

  public func burnToken(uid: T.UID, tokenId: T.TokenId, amount: Float): async() {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).burnToken(uid, amount);
    };
  };

  public func getPortfolio(uid: T.UID, tokenIds: [T.TokenId]): async [T.TokenInfo] {
    let tokens = Buffer.Buffer<T.TokenInfo>(100);

    Debug.print(debug_show ("before getPortfolio: " # Nat.toText(Cycles.balance())));

    for(item in tokenIds.vals()) {
      switch (tokenDirectory.get(item)) {
        case (null) {};
        case (?cid) {
          let token: T.TokenInfo = await TokenCanister(cid).getUserMinted(uid);
          tokens.add(token);
        };
      };
    };

    Debug.print(debug_show ("later getPortfolio: " # Nat.toText(Cycles.balance())));

    Buffer.toArray<T.TokenInfo>(tokens);
  };
}
