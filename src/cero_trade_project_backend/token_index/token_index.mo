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
import Debug "mo:base/Debug";

// canisters
import HttpService "canister:http_service";

// types
import T "../types";
import HT "../http_service/http_service_types";
import ICRC "../ICRC";
import ENV "../env";

shared({ caller = adminCaller }) actor class TokenIndex() = this {
  stable let ic : T.IC = actor ("aaaaa-aa");
  private func TokenCanister(cid: T.CanisterId): T.TokenInterface { actor (Principal.toText(cid)) };
  stable var wasm_module: Blob = "";


  var tokenDirectory: HM.HashMap<T.TokenId, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var tokenDirectoryEntries : [(T.TokenId, T.CanisterId)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { tokenDirectoryEntries := Iter.toArray(tokenDirectory.entries()) };
  system func postupgrade() {
    tokenDirectory := HM.fromIter<T.TokenId, T.CanisterId>(tokenDirectoryEntries.vals(), 16, Text.equal, Text.hash);
    tokenDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.AGENT_CANISTER_ID) == caller };

  /// get size of tokenDirectory collection
  public query func length(): async Nat { tokenDirectory.size() };

  /// register wasm module to dynamic token canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    _callValidation(caller);

    let branch = switch(ENV.DFX_NETWORK) {
      case("ic") "main";
      case("local") "develop";
      case _ throw Error.reject("No DFX_NETWORK provided");
    };
    let wasmModule = await HttpService.get("https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # branch # "/wasm_modules/token.json", { headers = [] });

    let parts = Text.split(Text.replace(Text.replace(wasmModule, #char '[', ""), #char ']', ""), #char ',');
    let wasm_array = Array.map<Text, Nat>(Iter.toArray(parts), func(part) {
      switch (Nat.fromText(part)) {
        case null 0;
        case (?n) n;
      }
    });
    let nums8 : [Nat8] = Array.map<Nat, Nat8>(wasm_array, Nat8.fromNat);

    // register wasm
    wasm_module := Blob.fromArray(nums8);

    // update deployed canisters
    for((tokenId, canister_id) in tokenDirectory.entries()) {
      await ic.install_code({
        arg = to_candid(tokenId);
        wasm_module;
        mode = #upgrade;
        canister_id;
      });
    };
  };

  /// register [tokenDirectory] collection
  public shared({ caller }) func registerToken(tokenId: Text): async Principal {
    _callValidation(caller);

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
          await ic.install_code({
            arg = to_candid(tokenId);
            wasm_module;
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
              startDate = "2024-04-29T19:43:34.000Z";
              endDate = "2024-05-29T19:48:31.000Z";
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
              dates = ["2024-04-29T19:43:34.000Z", "2024-05-29T19:48:31.000Z", "2024-05-29T19:48:31.000Z"];
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
  public shared({ caller }) func deleteToken(tokenId: Text): async () {
    T.adminValidation(caller, adminCaller);

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

  /// manage deployed canister status
  public shared({ caller }) func statusDeployedCanisterById(tokenId: T.TokenId): async {
    status: { #stopped; #stopping; #running };
    memory_size: Nat;
    cycles: Nat;
    settings: T.CanisterSettings;
    idle_cycles_burned_per_day: Nat;
    module_hash: ?[Nat8];
  } {
    T.adminValidation(caller, adminCaller);

    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add(20_949_972_000);
        return await ic.canister_status({ canister_id });
      };
    };
  };

  /// resume all deployed canisters
  public shared({ caller }) func startAllDeployedCanisters(): async () {
    T.adminValidation(caller, adminCaller);

    for(canister_id in tokenDirectory.vals()) {
      Cycles.add(20_949_972_000);
      await ic.start_canister({ canister_id });
    };
  };

  /// stop all deployed canisters
  public shared({ caller }) func stopAllDeployedCanisters(): async () {
    T.adminValidation(caller, adminCaller);

    for(canister_id in tokenDirectory.vals()) {
      Cycles.add(20_949_972_000);
      await ic.stop_canister({ canister_id });
    };
  };

  /// get canister id that allow current user
  public shared({ caller }) func getTokenCanister(tokenId: T.TokenId): async T.CanisterId {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) { throw Error.reject("Token not found"); };
      case (?cid) { return cid };
    };
  };

  public shared({ caller }) func getRemainingAmount(tokenId: T.TokenId): async T.TokenAmount {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) return await TokenCanister(cid).getRemainingAmount();
    };
  };

  public shared({ caller }) func getAssetInfo(tokenId: T.TokenId): async T.AssetInfo {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) return await TokenCanister(cid).getAssetInfo();
    };
  };

  public shared({ caller }) func mintTokenToUser(uid: T.UID, tokenId: T.TokenId, amount: T.TokenAmount, inMarket: T.TokenAmount): async() {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).mintToken(uid, amount, inMarket);
    };
  };

  public shared({ caller }) func burnToken(uid: T.UID, tokenId: T.TokenId, amount: T.TokenAmount, inMarket: T.TokenAmount): async() {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).burnToken(uid, amount, inMarket);
    };
  };

  // get token portfolio for a specific user
  public shared({ caller }) func getTokenPortfolio(uid: T.UID, tokenId: T.TokenId): async T.TokenInfo {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on Portfolio");
      case (?cid) return await TokenCanister(cid).getUserMinted(uid);
    };
  };

  public shared({ caller }) func getPortfolio(uid: T.UID, tokenIds: [T.TokenId], page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    data: [T.TokenInfo];
    totalPages: Nat;
  } {
    _callValidation(caller);

    // define page based on statement
    let startPage = switch(page) {
      case(null) 1;
      case(?value) value;
    };

    // define length based on statement
    let maxLength = switch(length) {
      case(null) 50;
      case(?value) value;
    };

    let tokens = Buffer.Buffer<T.TokenInfo>(50);

    // calculate range of elements returned
    let startIndex: Nat = (startPage - 1) * maxLength;
    var i = 0;

    Debug.print(debug_show ("before getPortfolio: " # Nat.toText(Cycles.balance())));


    for(tokenId in tokenIds.vals()) {
      if (i >= startIndex and i < startIndex + maxLength) {
        switch(tokenDirectory.get(tokenId)) {
          case(null) {};

          case(?cid) {
            let token: T.TokenInfo = await TokenCanister(cid).getUserMinted(uid);

            // filter by tokenId
            let filterRange: Bool = switch(mwhRange) {
              case(null) true;
              case(?range) token.totalAmount >= range[0] and token.totalAmount <= range[1];
            };

            if (filterRange) tokens.add(token);
          };
        };
      };
      i += 1;
    };


    let filteredTokens: [T.TokenInfo] = Array.filter<T.TokenInfo>(Buffer.toArray<T.TokenInfo>(tokens), func (item) {
      // by assetTypes
      let assetTypeMatches = switch (assetTypes) {
        case(null) true;
        case(?assets) {
          let assetType = Array.find<T.AssetType>(assets, func (assetType) { assetType == item.assetInfo.assetType });
          assetType != null
        };
      };

      // by country
      let countryMatches = switch (country) {
        case(null) true;
        case(?value) item.assetInfo.specifications.country == value;
      };

      assetTypeMatches and countryMatches;
    });


    Debug.print(debug_show ("later getPortfolio: " # Nat.toText(Cycles.balance())));
    
    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    {
      data = filteredTokens;
      totalPages;
    }
  };


  public shared({ caller }) func getSingleTokenInfo(tokenId: T.TokenId): async T.AssetInfo {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on cero trade");
      case (?cid) return await TokenCanister(cid).getAssetInfo();
    };
  };

  public shared({ caller }) func getTokensInfo(tokenIds: [T.TokenId]): async [T.AssetInfo] {
    _callValidation(caller);

    let tokens = Buffer.Buffer<T.AssetInfo>(50);

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

  public shared({ caller }) func checkUserToken(uid: T.UID, tokenId: T.TokenId): async Bool {
    _callValidation(caller);

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
  // private func _transfer(args: {
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


  public shared({ caller }) func purchaseToken(uid: T.UID, recipent: { uid: T.UID; ledger: ICRC.AccountIdentifier }, tokenId: T.TokenId, amount: T.TokenAmount, inMarket: T.TokenAmount): async T.BlockHash {
    _callValidation(caller);

    Debug.print("recipent ledger " # debug_show (recipent.ledger));

    let blockIndex: Nat64 = 12345678901234567890 /* transfer({ amount = { e8s = amount }; recipentLedger }) */;

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await TokenCanister(cid).purchaseToken(uid, recipent.uid, amount, inMarket);
    };

    blockIndex
  };
}
