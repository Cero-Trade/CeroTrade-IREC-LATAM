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
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Serde "mo:serde";
import Debug "mo:base/Debug";

// canisters
import HttpService "canister:http_service";

// types
import T "../types";
import HT "../http_service/http_service_types";
import ICRC "../ICRC";

shared(init_msg) actor class TokenIndex(ENVIRONMENT_BRANCH: Text) = this {
  stable let ic : T.IC = actor ("aaaaa-aa");
  private func TokenCanister(cid: T.CanisterId): T.TokenInterface { actor (Principal.toText(cid)) };
  stable var wasm_array : [Nat] = [];


  var tokenDirectory: HM.HashMap<Text, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var tokenDirectoryEntries : [(Text, T.CanisterId)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { tokenDirectoryEntries := Iter.toArray(tokenDirectory.entries()) };
  system func postupgrade() {
    tokenDirectory := HM.fromIter<Text, T.CanisterId>(tokenDirectoryEntries.vals(), 16, Text.equal, Text.hash);
    tokenDirectoryEntries := [];
  };

  /// get size of tokenDirectory collection
  public query func length(): async Nat { tokenDirectory.size() };

  /// register wasm module to dynamic token canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    assert init_msg.caller == caller;

    let wasmModule = await HttpService.get("https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # ENVIRONMENT_BRANCH # "/wasm_modules/token.json",
      { headers = []
    });

    let parts = Text.split(Text.replace(Text.replace(wasmModule, #char '[', ""), #char ']', ""), #char ',');
    wasm_array := Array.map<Text, Nat>(Iter.toArray(parts), func(part) {
      switch (Nat.fromText(part)) {
        case null 0;
        case (?n) n;
      }
    });
  };

  /// register [tokenDirectory] collection
  public shared({ caller }) func registerToken(tokenId: Text): async Principal {
    assert init_msg.caller == caller;

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
              tokenId;
              assetType = energy;
              startDate: Nat64 = 1714419814052;
              endDate: Nat64 = 1717012111263;
              co2Emission: Float = 11.22;
              radioactivityEmnission: Float = 10.20;
              volumeProduced: T.TokenAmount = 1000;
              deviceDetails = {
                name = "machine";
                deviceType = "type";
                group = energy;
                description = "description";
              };
              specifications = {
                deviceCode = "200";
                capacity: T.TokenAmount = 1000;
                location = "location";
                latitude: Float = 0;
                longitude: Float = 1;
                address = "address anywhere";
                stateProvince = "chile";
                country = "chile";
              };
              dates: [Nat64] = [1714419814052, 1717012111263, 1717012111263];
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

  public func getRemainingAmount(tokenId: T.TokenId): async T.TokenAmount {
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

  public func mintToken(uid: T.UID, tokenId: T.TokenId, amount: T.TokenAmount, inMarket: T.TokenAmount): async() {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).mintToken(uid, amount, inMarket);
    };
  };

  public func burnToken(uid: T.UID, tokenId: T.TokenId, amount: T.TokenAmount, inMarket: T.TokenAmount): async() {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).burnToken(uid, amount, inMarket);
    };
  };

  // get token portfolio for a specific user
  public func getTokenPortfolio(uid: T.UID, tokenId: T.TokenId): async T.TokenInfo {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on Portfolio");
      case (?cid) return await TokenCanister(cid).getUserMinted(uid);
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


  public func getSingleTokenInfo(tokenId: T.TokenId): async T.AssetInfo {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on cero trade");
      case (?cid) return await TokenCanister(cid).getAssetInfo();
    };
  };

  public func getTokensInfo(tokenIds: [T.TokenId]): async [T.AssetInfo] {
    let tokens = Buffer.Buffer<T.AssetInfo>(100);

    Debug.print(debug_show ("before getTokensInfo: " # Nat.toText(Cycles.balance())));

    for(item in tokenIds.vals()) {
      switch (tokenDirectory.get(item)) {
        case (null) {};
        case (?cid) {
          let token: T.AssetInfo = await TokenCanister(cid).getAssetInfo();
          tokens.add(token);
        };
      };
    };

    Debug.print(debug_show ("later getTokensInfo: " # Nat.toText(Cycles.balance())));

    Buffer.toArray<T.AssetInfo>(tokens);
  };

  public func checkUserToken(uid: T.UID, tokenId: T.TokenId): async Bool {
    try {
      switch (tokenDirectory.get(tokenId)) {
        case (null) return false;
        case (?cid) {
          let token = await TokenCanister(cid).getUserMinted(uid);
          return true;
        }
      };
    } catch (error) {
      return false;
    }
  };


  // TODO implements this transfer function to icp tokens
  // private func transfer(args: {
  //   amount: T.Price;
  //   recipentLedger: ICRC.AccountIdentifier;
  // }) : async Result.Result<IcpLedger.BlockIndex, Text> {
  //   Debug.print(
  //     "Transferring "
  //     # debug_show (args.amount)
  //     # " tokens to ledger "
  //     # debug_show (args.recipentLedger)
  //   );

  //   let transferArgs : IcpLedger.TransferArgs = {
  //     // can be used to distinguish between transactions
  //     memo = 0;
  //     // the amount we want to transfer
  //     amount = args.amount;
  //     // the ICP ledger charges 10_000 e8s for a transfer
  //     fee = { e8s = 10_000 };
  //     // we are transferring from the canisters default subaccount, therefore we don't need to specify it
  //     from_subaccount = null;
  //     // we take the principal and subaccount from the arguments and convert them into an account identifier
  //     to = Blob.toArray(args.recipentLedger);
  //     // a timestamp indicating when the transaction was created by the caller; if it is not specified by the caller then this is set to the current ICP time
  //     created_at_time = null;
  //   };

  //   try {
  //     // initiate the transfer
  //     let transferResult = await IcpLedger.transfer(transferArgs);

  //     // check if the transfer was successfull
  //     switch (transferResult) {
  //       case (#Err(transferError)) {
  //         return #err("Couldn't transfer funds:\n" # debug_show (transferError));
  //       };
  //       case (#Ok(blockIndex)) { return #ok blockIndex };
  //     };
  //   } catch (error : Error) {
  //     // catch any errors that might occur during the transfer
  //     return #err("Reject message: " # Error.message(error));
  //   };
  // };


  public func purchaseToken(uid: T.UID, recipent: { uid: T.UID; ledger: ICRC.AccountIdentifier }, tokenId: T.TokenId, amount: T.TokenAmount, inMarket: T.TokenAmount): async T.BlockHash {
    Debug.print("recipent ledger " # debug_show (recipent.ledger));

    let blockIndex: Nat64 = 12345678901234567890 /* transfer({ amount = { e8s = amount }; recipentLedger }) */;

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).purchaseToken(uid, recipent.uid, amount, inMarket);
    };

    blockIndex
  };
}
