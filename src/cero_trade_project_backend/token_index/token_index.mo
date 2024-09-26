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
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Serde "mo:serde";
import Debug "mo:base/Debug";

import ICRC1 "mo:icrc1-mo/ICRC1";

// interfaces
import Token "../token/token_interface";
import IC_MANAGEMENT "../ic_management_canister_interface";
import ICPTypes "../ICPTypes";
import HTTP "../http_service/http_service_interface";

// types
import T "../types";
import ENV "../env";

shared({ caller = owner }) actor class TokenIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;

  stable var comissionHolder: ICPTypes.Account = { owner; subaccount = null };

  var tokenDirectory: HM.HashMap<T.TokenId, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var tokenDirectoryEntries : [(T.TokenId, T.CanisterId)] = [];

  type AssetResponse = {
    item_volume: Text;
    asset_assetId: Text;
    asset_endDate: Text;
    asset_location: Text;
    asset_maxVolume: Text;
    asset_startDate: Text;
    asset_co2Produced: Text;
    asset_radioactiveProduced: Text;
    device_code: Text;
    device_name: Text;
    device_type: Text;
    device_longitude: Text;
    device_latitude: Text;
    device_description: Text;
    device_country: Text;
  };

  type TransactionResponse = {
    id: Nat;
    transactionId: Text;
    sourceAccountCode: Text;
    destinationAccountCode: Text;
    transactionType: Text;
    volume: Text;
    timestamp: Text;
    items: [AssetResponse];
    processed: Bool;
    createdAt: Text;
    updatedAt: Text;
  };


  /// funcs to persistent collection state
  system func preupgrade() { tokenDirectoryEntries := Iter.toArray(tokenDirectory.entries()) };
  system func postupgrade() {
    tokenDirectory := HM.fromIter<T.TokenId, T.CanisterId>(tokenDirectoryEntries.vals(), 16, Text.equal, Text.hash);
    tokenDirectoryEntries := [];
  };

  private func _callValidation(caller: Principal) { assert Principal.fromText(ENV.CANISTER_ID_AGENT) == caller };

  /// get size of tokenDirectory collection
  public query func length(): async Nat { tokenDirectory.size() };

  /// get canister controllers
  public shared({ caller }) func getControllers(): async ?[Principal] {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    await IC_MANAGEMENT.getControllers(Principal.fromActor(this));
  };

  /// get comisison holder
  public shared({ caller }) func getComisisonHolder(): async ICPTypes.Account {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    comissionHolder
  };

  /// set comisison holder
  public shared({ caller }) func setComisisonHolder(holder: ICPTypes.Account): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    comissionHolder := holder
  };

  /// register canister controllers
  public shared({ caller }) func registerControllers(): async () {
    _callValidation(caller);

    controllers := await IC_MANAGEMENT.getControllers(Principal.fromActor(this));
  };

  /// register wasm module to dynamic token canister, only admin can run it
  public shared({ caller }) func registerWasmArray(): async() {
    _callValidation(caller);

    // register wasm
    wasm_module := await IC_MANAGEMENT.getWasmModule(#token("token"));

    // update deployed canisters
    for((tokenId, canister_id) in tokenDirectory.entries()) {
      await IC_MANAGEMENT.ic.install_code({
        arg = to_candid({
          name = await Token.canister(canister_id).icrc1_name();
          symbol = await Token.canister(canister_id).icrc1_symbol();
          logo = await Token.canister(canister_id).icrc1_logo();
          assetMetadata = await Token.canister(canister_id).assetMetadata();
          comission = Nat64.toNat(T.getCeroComission());
          comissionHolder;
        });
        wasm_module;
        mode = #upgrade;
        canister_id;
      });
    };
  };

  stable var SolarId: Nat = 0;
  stable var WindId: Nat = 0;
  stable var HydroElectricId: Nat = 0;
  stable var ThermalId: Nat = 0;
  stable var OtherId: Nat = 0;

  private func buildSymbol(assetType: T.AssetType): Text {
    var tokenId: Nat = 0;

    let symbol = switch(assetType) {
      case (#Solar(_)) {
        SolarId := SolarId + 1;
        tokenId := SolarId;
        "SOL"
      };
      case (#Wind(_)) {
        WindId := WindId + 1;
        tokenId := WindId;
        "WI"
      };
      case (#HydroElectric(_)) {
        HydroElectricId := HydroElectricId + 1;
        tokenId := HydroElectricId;
        "HE"
      };
      case (#Thermal(_)) {
        ThermalId := ThermalId + 1;
        tokenId := ThermalId;
        "TM"
      };
      case (#Other(_)) {
        OtherId := OtherId + 1;
        tokenId := OtherId;
        "OTH"
      };
    };

    symbol # Nat.toText(tokenId)
  };

  /// register [tokenDirectory] collection
  private func registerToken<system>(assetMetadata: T.AssetInfo): async T.CanisterId {
    let cid = switch (tokenDirectory.get(assetMetadata.tokenId)) {

      // get token
      case (?cid) cid;

      // register token in case doesnt exists
      case (null) {
        Debug.print(debug_show ("before registerToken: " # Nat.toText(Cycles.balance())));

        Cycles.add<system>(T.cyclesCreateCanister);
        /// create canister
        let { canister_id } = await IC_MANAGEMENT.ic.create_canister({
          settings = ?{
            controllers = switch(controllers) {
              case(null) null;
              case(?value) {
                let currentControllers = Buffer.fromArray<Principal>(value);
                currentControllers.add(Principal.fromActor(this));
                ?Buffer.toArray<Principal>(currentControllers);
              };
            };
            compute_allocation = null;
            memory_allocation = null;
            freezing_threshold = null;
          }
        });

        Debug.print(debug_show ("later create_canister: " # Nat.toText(Cycles.balance())));

        // install canister code
        await IC_MANAGEMENT.ic.install_code({
          arg = to_candid({
            name = assetMetadata.deviceDetails.name; // SOL4
            symbol = buildSymbol(assetMetadata.deviceDetails.deviceType); // "SOL4"
            logo = ""; // colocar imagen de cero trade + tipo de energia, guardar en un bucket estos logos
            assetMetadata;
            comission = Nat64.toNat(T.getCeroComission());
            comissionHolder;
          });
          wasm_module;
          mode = #install;
          canister_id;
        });

        Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

        await Token.canister(canister_id).admin_init();

        tokenDirectory.put(assetMetadata.tokenId, canister_id);
        canister_id;
      };
    };

    cid
  };

  /// delete [tokenDirectory] collection
  public shared({ caller }) func deleteToken<system>(tokenId: Text): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
        await IC_MANAGEMENT.ic.delete_canister({ canister_id });
        tokenDirectory.delete(tokenId)
      };
    }
  };

  /// manage deployed canister status
  public shared({ caller }) func statusDeployedCanisterById<system>(tokenId: T.TokenId): async {
    status: { #stopped; #stopping; #running };
    memory_size: Nat;
    cycles: Nat;
    settings: IC_MANAGEMENT.CanisterSettings;
    idle_cycles_burned_per_day: Nat;
    module_hash: ?[Nat8];
  } {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        return await IC_MANAGEMENT.ic.canister_status({ canister_id });
      };
    };
  };

  /// resume all deployed canisters.
  ///
  /// only resume one if provide canister id
  public shared({ caller }) func startDeployedCanister<system>(cid: ?T.CanisterId): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(cid) {
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.start_canister({ canister_id });
      };
      case(null) {
        for(canister_id in tokenDirectory.vals()) {
          Cycles.add<system>(T.cycles);
          await IC_MANAGEMENT.ic.start_canister({ canister_id });
        };
      };
    };
  };

  /// stop all deployed canisters.
  ///
  /// only stop one if provide canister id
  public shared({ caller }) func stopDeployedCanister<system>(cid: ?T.CanisterId): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(cid) {
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
      };
      case(null) {
        for(canister_id in tokenDirectory.vals()) {
          Cycles.add<system>(T.cycles);
          await IC_MANAGEMENT.ic.stop_canister({ canister_id });
        };
      };
    };
  };

  /// stop all deployed canisters and delete
  ///
  /// only delete one if provide canister id
  public shared({ caller }) func deleteDeployedCanister<system>(cid: ?T.CanisterId): async () {
    _callValidation(caller);

    switch(cid) {
      case(?canister_id) {
        Cycles.add<system>(T.cycles);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
        await IC_MANAGEMENT.ic.delete_canister({ canister_id });

        for((tokenId, cid) in tokenDirectory.entries()) {
          if (cid == canister_id) return tokenDirectory.delete(tokenId);
        };
      };
      case(null) {
        for((tokenId, canister_id) in tokenDirectory.entries()) {
          Cycles.add<system>(T.cycles);
          await IC_MANAGEMENT.ic.stop_canister({ canister_id });
          await IC_MANAGEMENT.ic.delete_canister({ canister_id });
          tokenDirectory.delete(tokenId);
        };
      };
    };
  };

  public shared({ caller }) func getTokensInCeroTrade(): async [(T.TokenId, T.CanisterId)] {
    IC_MANAGEMENT.adminValidation(caller, controllers);
    Iter.toArray(tokenDirectory.entries())
  };

  // ======================================================================================================== //

  /// get canister id that allow current token
  public query func getTokenCanister(tokenId: T.TokenId): async T.CanisterId {
    switch (tokenDirectory.get(tokenId)) {
      case (null) { throw Error.reject("Token not found on Cero Trade"); };
      case (?cid) { return cid };
    };
  };

  public func getAssetInfo(tokenId: T.TokenId): async T.AssetInfo {
    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on Cero Trade");
      case (?cid) return await Token.canister(cid).assetMetadata();
    };
  };


  public shared({ caller }) func importUserTokens(uid: T.UID): async [{ mwh: T.TokenAmount; assetInfo: T.AssetInfo }] {
    _callValidation(caller);

    let canister_status = await IC_MANAGEMENT.ic.canister_status({ canister_id = Principal.fromActor(this) });
    if (canister_status.cycles <= 2_500_000_000_000) throw Error.reject("Token canister have not enough cycles to performe this operation");

    let assetsJson = await HTTP.canister.post({
      url = HTTP.apiUrl # "transactions/import";
      port = null;
      uid = ?uid;
      headers = [];
      bodyJson = "{}";
    });

    // used hashmap to find faster elements using Hash
    // this Hash have limitation when data length is too large.
    // In this case, would consider changing to another more effective method.
    let assetsMetadata = HM.HashMap<T.TokenId, { mwh: T.TokenAmount; assetInfo: T.AssetInfo }>(16, Text.equal, Text.hash);

    // TODO this code below exists in case need test it
    // assetsMetadata.put("2", {
    //   mwh = 200_000_000;
    //   assetInfo = {
    //     tokenId = "2";
    //     startDate = "2024-04-29T19:43:34.000Z";
    //     endDate = "2024-05-29T19:48:31.000Z";
    //     co2Emission = "11.22";
    //     radioactivityEmission = "10.20";
    //     volumeProduced: T.TokenAmount = 200_000_000_000;
    //     deviceDetails = {
    //       name = "machine";
    //       deviceType = #HydroElectric("Hydro-Electric");
    //       description = "description";
    //     };
    //     specifications = {
    //       deviceCode = "200";
    //       location = "location";
    //       latitude = "0.1";
    //       longitude = "1.0";
    //       country = "CL";
    //     };
    //   };
    // });

    switch(Serde.JSON.fromText(assetsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize asset data");
      case(#ok(blob)) {
        let transactionResponse: ?[TransactionResponse] = from_candid(blob);

        switch(transactionResponse) {
          case(null) throw Error.reject("cannot serialize asset data");
          case(?response) {
            for({ items } in response.vals()) {
              for(assetResponse in items.vals()) {
                // TODO review mwh value assignment
                assetsMetadata.put(assetResponse.asset_assetId, {
                  mwh = await T.textToToken(assetResponse.item_volume, null);
                  assetInfo = await buildAssetInfo(assetResponse);
                });
              };
            };
          };

        };
      };
    };


    for((key, { mwh; assetInfo }) in assetsMetadata.entries()) {
      // get token or register in case doesnt exists
      let cid = await registerToken(assetInfo);

      // mint tokens to user
      let transferResult: ICRC1.TransferResult = await Token.canister(cid).mint({
        to = {
          owner = uid;
          subaccount = null;
        };
        amount = mwh;
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        memo = null;
      });

      switch(transferResult) {
        case(#Ok(value)) Debug.print("#Ok - minted " # Nat.toText(mwh) # " tokens in tx index: " # Nat.toText(value));

        case(#Err(error)) {
          Debug.print(switch(error) {
            case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
            case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
            case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
            case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
            case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
            case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
            case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
            case (#TooOld) "#TooOld";
          });

          assetsMetadata.delete(key);
        };
      };
    };

    Iter.toArray(assetsMetadata.vals())
  };


  public shared({ caller }) func mintTokenToUser(recipent: T.BID, tokenId: T.TokenId, amount: T.TokenAmount): async (T.TxIndex, T.AssetInfo) {
    _callValidation(caller);

    let assetsJson = await HTTP.canister.get({
      url = HTTP.apiUrl # "assets/" # tokenId;
      port = null;
      uid = null;
      headers = [];
    });

    let assetMetadata: T.AssetInfo = switch(Serde.JSON.fromText(assetsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize asset data");
      case(#ok(blob)) {
        let assetResponse: ?AssetResponse = from_candid(blob);

        switch(assetResponse) {
          case(null) throw Error.reject("cannot serialize asset data");
          case(?value) await buildAssetInfo(value);
        };
      };
    };

    // get token or register in case doesnt exists
    let cid = await registerToken(assetMetadata);

    // mint token to user
    let transferResult: ICRC1.TransferResult = await Token.canister(cid).mint({
      to = {
        owner = recipent;
        subaccount = null;
      };
      amount;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      memo = null;
    });

    let txIndex = switch(transferResult) {
      case(#Err(error)) throw Error.reject(switch(error) {
        case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
        case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
        case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
        case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
        case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
        case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
        case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
        case (#TooOld) "#TooOld";
      });
      case(#Ok(value)) value;
    };

    (txIndex, assetMetadata)
  };

  // helper function used to build [AssetInfo] from AssetResponse
  private func buildAssetInfo(asset: AssetResponse): async T.AssetInfo {
    let deviceType: T.AssetType = switch(asset.device_type) {
      case("Solar") #Solar("Solar");
      case("Wind") #Wind("Wind");
      case("Hydro-Electric") #HydroElectric("Hydro-Electric");
      case("Thermal") #Thermal("Thermal");
      case _ #Other("Other");
    };

    // TODO review specification values assignment
    {
      tokenId = asset.asset_assetId;
      startDate = asset.asset_startDate;
      endDate = asset.asset_endDate;
      co2Emission = asset.asset_co2Produced;
      radioactivityEmission = asset.asset_radioactiveProduced;
      volumeProduced = await T.textToToken(asset.asset_maxVolume, null);
      deviceDetails = {
        name = asset.device_name;
        deviceType;
        description = asset.device_description;
      };
      specifications = {
        deviceCode = asset.device_code;
        location = asset.asset_location;
        latitude = asset.device_latitude;
        longitude = asset.device_longitude;
        country = asset.device_country;
      };
    };
  };

  // get token portfolio for a specific user
  public shared({ caller }) func getSingleTokenInfo(uid: T.UID, tokenId: T.TokenId): async T.TokenInfo {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on Portfolio");
      case (?cid) {
        let token_balance = await Token.canister(cid).token_balance({ owner = uid; subaccount = null });

        {
          tokenId;
          totalAmount = token_balance.balance;
          assetInfo = token_balance.assetMetadata;
          inMarket = 0;
        }
      };
    };
  };

  // // get token portfolio for a specific user
  // public shared({ caller }) func getTokenPortfolio(uid: T.UID, tokenId: T.TokenId): async T.TokenInfo {
  //   _callValidation(caller);

  //   switch (tokenDirectory.get(tokenId)) {
  //     case (null) throw Error.reject("Token not found on Portfolio");
  //     case (?cid) {
  //       let token_balance = await Token.canister(cid).token_balance({ owner = uid; subaccount = null });

  //       {
  //         tokenId;
  //         totalAmount = token_balance.balance;
  //         assetInfo = token_balance.assetMetadata;
  //         inMarket = 0;
  //       }
  //     };
  //   };
  // };

  // /// get user portfolio
  // public shared({ caller }) func getPortfolio(uid: T.UID, page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
  //   tokens: [T.TokenInfo];
  //   txIds: [T.TransactionId];
  //   totalPages: Nat;
  // } {
  //   _callValidation(caller);

  //   // fetch user to get token ids
  //   let portfolioJson = await HTTP.canister.get({
  //     url = HTTP.apiUrl # "users/portfolio";
  //     port = null;
  //     uid = ?uid;
  //     headers = [];
  //   });

  //   Debug.print("portfolioJson " # debug_show (portfolioJson));
  //   let portfolioIds: { tokenIds: [T.TokenId]; txIds: [T.TransactionId] } = switch(Serde.JSON.fromText(portfolioJson, null)) {
  //     case(#err(_)) throw Error.reject("cannot serialize asset data");
  //     case(#ok(blob)) {
  //       let portfolio: ?{ tokenIds: ?[T.TokenId]; txIds: ?[T.TransactionId]; } = from_candid(blob);
  //       Debug.print("portfolio " # debug_show (portfolio));

  //       switch(portfolio) {
  //         case(null) throw Error.reject("cannot serialize asset data");
  //         case(?value) {
  //           {
  //             tokenIds = switch(value.tokenIds) {
  //               case(null) [];
  //               case(?value) value;
  //             };
  //             txIds = switch(value.txIds) {
  //               case(null) [];
  //               case(?value) value;
  //             };
  //           }
  //         };
  //       };
  //     };
  //   };

  //   // define page based on statement
  //   let startPage = switch(page) {
  //     case(null) 1;
  //     case(?value) value;
  //   };

  //   // define length based on statement
  //   let maxLength = switch(length) {
  //     case(null) 50;
  //     case(?value) value;
  //   };

  //   let tokens = Buffer.Buffer<T.TokenInfo>(50);

  //   // calculate range of elements returned
  //   let startIndex: Nat = (startPage - 1) * maxLength;
  //   var i = 0;

  //   Debug.print(debug_show ("before getPortfolio: " # Nat.toText(Cycles.balance())));


  //   for(tokenId in portfolioIds.tokenIds.vals()) {
  //     if (i >= startIndex and i < startIndex + maxLength) {
  //       switch(tokenDirectory.get(tokenId)) {
  //         case(null) {};

  //         case(?cid) {
  //           let token_balance = await Token.canister(cid).token_balance({ owner = uid; subaccount = null });
  //           let token = {
  //             tokenId;
  //             totalAmount = token_balance.balance;
  //             assetInfo = token_balance.assetMetadata;
  //             inMarket = 0;
  //           };

  //           // filter by tokenId
  //           let filterRange: Bool = switch(mwhRange) {
  //             case(null) true;
  //             case(?range) token.totalAmount >= range[0] and token.totalAmount <= range[1];
  //           };

  //           // filter by assetTypes
  //           let filterAssetType = switch (assetTypes) {
  //             case(null) true;
  //             case(?assets) {
  //               let assetType = Array.find<T.AssetType>(assets, func (assetType) { assetType == token.assetInfo.deviceDetails.deviceType });
  //               assetType != null
  //             };
  //           };

  //           // filter by country
  //           let filterCountry = switch (country) {
  //             case(null) true;
  //             case(?value) token.assetInfo.specifications.country == value;
  //           };

  //           if (token.totalAmount > 0 and filterRange and filterAssetType and filterCountry) tokens.add(token);
  //         };
  //       };
  //     };
  //     i += 1;
  //   };


  //   Debug.print(debug_show ("later getPortfolio: " # Nat.toText(Cycles.balance())));

  //   var totalPages: Nat = i / maxLength;
  //   if (totalPages <= 0) totalPages := 1;

  //   {
  //     tokens = Buffer.toArray<T.TokenInfo>(tokens);
  //     txIds = portfolioIds.txIds;
  //     totalPages;
  //   }
  // };


  public shared({ caller }) func getTokensInfo(tokenIds: [T.TokenId]): async [T.AssetInfo] {
    _callValidation(caller);

    let tokens = Buffer.Buffer<T.AssetInfo>(50);

    Debug.print(debug_show ("before getTokensInfo: " # Nat.toText(Cycles.balance())));

    for(item in tokenIds.vals()) {
      switch (tokenDirectory.get(item)) {
        case (null) {};
        case (?cid) {
          let token: T.AssetInfo = await Token.canister(cid).assetMetadata();
          tokens.add(token);
        };
      };
    };

    Debug.print(debug_show ("later getTokensInfo: " # Nat.toText(Cycles.balance())));

    Buffer.toArray<T.AssetInfo>(tokens);
  };

  public shared({ caller }) func balanceOf(uid: T.UID, tokenId: T.TokenId): async ICRC1.Balance {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) 0;
      case (?cid) await Token.canister(cid).icrc1_balance_of({ owner = uid; subaccount = null });
    };
  };

  public shared({ caller }) func balanceOfBatch(uid: T.UID, tokenIds: [T.TokenId]): async [(T.TokenId, ICRC1.Balance)] {
    _callValidation(caller);

    let hashMap: HM.HashMap<T.TokenId, Nat> = HM.HashMap(16, Text.equal, Text.hash);

    for(tokenId in tokenIds.vals()) {
      let balance = switch (tokenDirectory.get(tokenId)) {
        case (null) 0;
        case (?cid) await Token.canister(cid).icrc1_balance_of({ owner = uid; subaccount = null });
      };

      hashMap.put(tokenId, balance);
    };

    Iter.toArray(hashMap.entries());
  };

  public shared({ caller }) func sellInMarketplace(seller: T.UID, tokenId: T.TokenId, amount: T.TokenAmount): async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).transferInMarketplace({
        from = {
          owner = seller;
          subaccount = null;
        };
        to = {
          owner = Principal.fromText(ENV.CANISTER_ID_MARKETPLACE);
          subaccount = null;
        };
        amount;
      });
    };

    switch(transferResult) {
      case(#Err(error)) throw Error.reject(switch(error) {
        case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
        case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
        case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
        case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
        case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
        case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
        case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
        case (#TooOld) "#TooOld";
      });
      case(#Ok(value)) value;
    };
  };


  public shared({ caller }) func takeOffMarketplace(seller: T.UID, tokenId: T.TokenId, amount: T.TokenAmount): async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).transferInMarketplace({
        from = {
          owner = Principal.fromText(ENV.CANISTER_ID_MARKETPLACE);
          subaccount = null;
        };
        to = {
          owner = seller;
          subaccount = null;
        };
        amount;
      });
    };

    switch(transferResult) {
      case(#Err(error)) throw Error.reject(switch(error) {
        case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
        case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
        case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
        case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
        case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
        case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
        case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
        case (#TooOld) "#TooOld";
      });
      case(#Ok(value)) value;
    };
  };


  public shared({ caller }) func purchaseToken(buyer: T.UID, seller: T.BID, tokenId: T.TokenId, amount: T.TokenAmount, priceE8S: T.Price): async (T.TxIndex, T.AssetInfo) {
    _callValidation(caller);

    let (transferResult, assetInfo): (ICRC1.TransferResult, T.AssetInfo) = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).purchaseInMarketplace({
        marketplace = { owner = Principal.fromText(ENV.CANISTER_ID_MARKETPLACE); subaccount = null };
        seller = { owner = seller; subaccount = null };
        buyer = { owner = buyer; subaccount = null };
        amount;
        priceE8S;
      });
    };

    let txIndex = switch(transferResult) {
      case(#Err(error)) throw Error.reject(switch(error) {
        case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
        case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
        case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
        case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
        case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
        case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
        case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
        case (#TooOld) "#TooOld";
      });
      case(#Ok(value)) value;
    };

    (txIndex, assetInfo)
  };

  public shared ({ caller }) func requestRedeem(owner: T.UID, items: [T.RedemptionItem], { returns: Bool }) : async [T.RedemptionRequest] {
    _callValidation(caller);

    let redemptionRequest = Buffer.Buffer<T.RedemptionRequest>(16);

    for({ id; volume; } in items.vals()) {
      let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(id)) {
        case (null) throw Error.reject("Token not found");
        case (?cid) await Token.canister(cid).requestRedeem({
          owner = {
            owner = owner;
            subaccount = null;
          };
          amount = volume;
        }, { returns });
      };

      let txIndex = switch(transferResult) {
        case(#Err(error)) throw Error.reject(switch(error) {
          case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
          case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
          case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
          case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
          case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
          case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
          case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
          case (#TooOld) "#TooOld";
        });
        case(#Ok(value)) value;
      };

      redemptionRequest.add({ id; txIndex; });
    };

    Buffer.toArray<T.RedemptionRequest>(redemptionRequest);
  };

  public shared({ caller }) func redeemRequested(profile: T.UserProfile, notification: T.NotificationInfo): async [T.RedemptionItemPdf] {
    _callValidation(caller);

    let items = switch(notification.items) {
      case(null) throw Error.reject("items not provided");
      case(?value) value;
    };

    var volume: Nat = 0;
    // summatory of volumes
    for ({ volume = vol } in items.vals()) { volume += vol };

    let periodStart = switch(notification.redeemPeriodStart) {
      case(null) throw Error.reject("redeemPeriodStart not provided");
      case(?value) value;
    };
    let periodEnd = switch(notification.redeemPeriodEnd) {
      case(null) throw Error.reject("redeemPeriodEnd not provided");
      case(?value) value;
    };
    let locale = switch(notification.redeemLocale) {
      case(null) throw Error.reject("redeemLocale not provided");
      case(?value) value;
    };

    // TODO ---> just for testing here
    // let redemptionPdf = [1,2,3,4,5,6,7,9];

    // - volume: El volumen de I-RECs que se quiere redimir.
    // - beneficiary: El identificador del beneficiario de la redención.
    // - items: Un url identificador de los items. Esta información debe traerse al momento de hacer el importe de los IRECs.
    // - periodStart y periodEnd: Las fechas de inicio y fin del periodo de redención. Esto debe ser un input del usuario.
    // - locale: El idioma en que se quiere obtener el "redemption statement" (ej. "en", "es"). Este debe ser un input del usuario.
    let pdfJson = await HTTP.canister.post({
        url = HTTP.apiUrl # "redemptions";
        port = null;
        uid = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          volume;
          beneficiary = profile.evidentBID;
          items;
          periodStart;
          periodEnd;
          locale;
        }), ["volume", "beneficiary", "items", "periodStart", "periodEnd", "locale"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
      Debug.print("✅ response --> " # debug_show (pdfJson));

    switch(Serde.JSON.fromText(pdfJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize PDF file data");
      case(#ok(blob)) {
        let response: ?{ pdf: [Nat] } = from_candid(blob);

        switch(response) {
          case(null) throw Error.reject("cannot serialize PDF file data");
          case(?pdfItems) {
            let redemptionItems = Buffer.Buffer<T.RedemptionItemPdf>(16);

            for({ id; volume } in items.vals()) {
              let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(id)) {
                case (null) throw Error.reject("Token not found");
                case (?cid) await Token.canister(cid).redeemRequested({
                  owner = {
                    owner = notification.receivedBy;
                    subaccount = null;
                  };
                  amount = volume;
                });
              };

              let txIndex = switch(transferResult) {
                case(#Err(error)) throw Error.reject(switch(error) {
                  case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
                  case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
                  case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
                  case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
                  case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
                  case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
                  case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
                  case (#TooOld) "#TooOld";
                });
                case(#Ok(value)) value;
              };

              let { pdf } = pdfItems;
              // let { pdf } = switch(Array.find<{ id: T.TokenId; pdf: [Nat] }>(pdfItems, func x = x.id == id)) {
              //   case(null) throw Error.reject("TokenId not found in redmeption");
              //   case(?value) value;
              // };

              redemptionItems.add({ id; txIndex; volume; pdf = Array.map<Nat, Nat8>(pdf, func x = Nat8.fromNat(x)); });
            };

            Buffer.toArray<T.RedemptionItemPdf>(redemptionItems);
          }
        };
      };
    };
  };

  public shared({ caller }) func redeem(owner: T.UID, evidentBID: T.EvidentBID, items: [T.RedemptionItem], periodStart: Text, periodEnd: Text, locale: Text): async [T.RedemptionItemPdf] {
    _callValidation(caller);

    var volume: Nat = 0;
    // summatory of volumes
    for ({ volume = vol } in items.vals()) { volume += vol };

    // TODO ---> just for testing here
    // let redemptionPdf = [1,2,3,4,5,6,7,9];

    // - volume: El volumen de I-RECs que se quiere redimir.
    // - beneficiary: El identificador del beneficiario de la redención.
    // - items: Un url identificador de los items. Esta información debe traerse al momento de hacer el importe de los IRECs.
    // - periodStart y periodEnd: Las fechas de inicio y fin del periodo de redención. Esto debe ser un input del usuario.
    // - locale: El idioma en que se quiere obtener el "redemption statement" (ej. "en", "es"). Este debe ser un input del usuario.
    let pdfJson = await HTTP.canister.post({
        url = HTTP.apiUrl # "redemptions";
        port = null;
        uid = null;
        headers = [];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          volume = 1000000/*  = Nat.toText(volume) */;
          beneficiary = "01J1QST7FGRGACW0DN4583NZ7X";
          items = [{
            id = "01J5QX61TEQASM6XE429SPEP0J";
            volume = 1000000;
          }]/*  = Array.map<T.RedemptionItem, { id: Text; volume: Text }>(items, func x = { id = x.id; volume = Nat.toText(x.volume) }) */;
          periodStart;
          periodEnd;
          locale;
        }), ["volume", "beneficiary", "items", "periodStart", "periodEnd", "locale"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
      Debug.print("✅ response --> " # debug_show (pdfJson));

    switch(Serde.JSON.fromText(pdfJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize PDF file data");
      case(#ok(blob)) {
        let response: ?{ pdf: [Nat] } = from_candid(blob);

        switch(response) {
          case(null) throw Error.reject("cannot serialize PDF file data");
          case(?pdfItems) {
            let redemptionItems = Buffer.Buffer<T.RedemptionItemPdf>(16);

            for({ id; volume; } in items.vals()) {
              let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(id)) {
                case (null) throw Error.reject("Token not found");
                case (?cid) await Token.canister(cid).redeem({
                  owner = {
                    owner = owner;
                    subaccount = null;
                  };
                  amount = volume;
                });
              };

              let txIndex = switch(transferResult) {
                case(#Err(error)) throw Error.reject(switch(error) {
                  case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
                  case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
                  case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
                  case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
                  case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
                  case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
                  case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
                  case (#TooOld) "#TooOld";
                });
                case(#Ok(value)) value;
              };

              let { pdf } = pdfItems;
              // let { pdf } = switch(Array.find<{ id: T.TokenId; pdf: [Nat] }>(pdfItems, func x = x.id == id)) {
              //   case(null) throw Error.reject("TokenId not found in redmeption");
              //   case(?value) value;
              // };

              redemptionItems.add({ id; txIndex; volume; pdf = Array.map<Nat, Nat8>(pdf, func x = Nat8.fromNat(x)); });
            };

            Buffer.toArray<T.RedemptionItemPdf>(redemptionItems);
          }
        };
      };
    };
  };

  type BurnedTokenIndex = {
    tokenAmount: T.TokenAmount;
    txIndex: T.TxIndex;
  };

  public shared ({ caller }) func burnUserTokens(owner: T.UID, tokenId: T.TokenId, amount: T.TokenAmount, amountInMarket: T.TokenAmount) : async [BurnedTokenIndex] {
    _callValidation(caller);

    let cid = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?value) value;
    };

    let txs = Buffer.Buffer<BurnedTokenIndex>(2);

    if (amount > 0) {
      let transferResult: ICRC1.TransferResult = await Token.canister(cid).burnUserTokens({
        owner = {
          owner = owner;
          subaccount = null;
        };
        amount;
      });

      let txIndex = switch(transferResult) {
        case(#Err(error)) throw Error.reject(switch(error) {
          case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
          case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
          case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
          case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
          case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
          case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
          case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
          case (#TooOld) "#TooOld";
        });
        case(#Ok(value)) value;
      };

      txs.add({ tokenAmount = amount; txIndex });
    };

    if (amountInMarket > 0) {
      let transferResult: ICRC1.TransferResult = await Token.canister(cid).burnUserTokens({
        owner = {
          owner = Principal.fromText(ENV.CANISTER_ID_MARKETPLACE);
          subaccount = null;
        };
        amount = amountInMarket;
      });

      let txIndex = switch(transferResult) {
        case(#Err(error)) throw Error.reject(switch(error) {
          case (#BadBurn {min_burn_amount}) "#BadBurn: " # Nat.toText(min_burn_amount);
          case (#BadFee {expected_fee}) "#BadFee: " # Nat.toText(expected_fee);
          case (#CreatedInFuture {ledger_time}) "#CreatedInFuture: " # Nat64.toText(ledger_time);
          case (#Duplicate {duplicate_of}) "#Duplicate: " # Nat.toText(duplicate_of);
          case (#GenericError {error_code; message}) "#GenericError: " # Nat.toText(error_code) # " " # message;
          case (#InsufficientFunds {balance}) "#InsufficientFunds: " # Nat.toText(balance);
          case (#TemporarilyUnavailable) "#TemporarilyUnavailable";
          case (#TooOld) "#TooOld";
        });
        case(#Ok(value)) value;
      };

      txs.add({ tokenAmount = amount; txIndex });
    };

    Buffer.toArray<BurnedTokenIndex>(txs);
  };
}
