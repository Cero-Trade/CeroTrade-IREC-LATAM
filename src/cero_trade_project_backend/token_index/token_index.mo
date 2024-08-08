import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Cycles "mo:base/ExperimentalCycles";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
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

// canisters
import HttpService "canister:http_service";

// interfaces
import IC_MANAGEMENT "../ic_management_canister_interface";
import Token "../token/token_interface";
import ICPTypes "../ICPTypes";

// types
import T "../types";
import HT "../http_service/http_service_types";
import ENV "../env";

shared({ caller = owner }) actor class TokenIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;

  stable var comissionHolder: ICPTypes.Account = { owner; subaccount = null };

  var tokenDirectory: HM.HashMap<T.TokenId, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var tokenDirectoryEntries : [(T.TokenId, T.CanisterId)] = [];

  type AssetResponse = {
    tokenId: Text;
    startDate: Text;
    endDate: Text;
    co2Emission: Text;
    radioactivityEmnission: Text;
    volumeProduced: Text;
    // deviceDetails
    name: Text;
    deviceType: Text;
    description: Text;
    // specifications
    deviceCode: Text;
    capacity: Text;
    location: Text;
    latitude: Text;
    longitude: Text;
    address: Text;
    stateProvince: Text;
    country: Text;
    dates: [Text];
  };

  type ItemResponse = {
    source: Text;
    volume: Text;
    assetId: Text;
    assetDetails: AssetResponse;
  };

  type TransactionResponse = {
    id: Nat;
    transactionId: Text;
    sourceAccountCode: Text;
    transactionType: Text;
    volume: Text;
    timestamp: Text;
    items: [ItemResponse];
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

    let branch = switch(ENV.DFX_NETWORK) {
      case("ic") "main";
      case _ "develop";
    };
    let wasmModule = await HttpService.get({
      url = "https://raw.githubusercontent.com/Cero-Trade/mvp1.0/" # branch # "/wasm_modules/token.json";
      port = null;
      headers = [];
    });

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
        let _ = tokenDirectory.remove(tokenId)
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

  /// get canister id that allow current token
  public query func getTokenCanister(tokenId: T.TokenId): async T.CanisterId {
    switch (tokenDirectory.get(tokenId)) {
      case (null) { throw Error.reject("Token not found"); };
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

    let tokenHeader = await HT.tokenAuthFromUser(uid);

    let assetsJson = await HttpService.get({
      url = HT.apiUrl # "transactions/fetchByUser";
      port = null;
      headers = [tokenHeader];
    });

    // used hashmap to find faster elements using Hash
    // this Hash have limitation when data length is too large.
    // In this case, would consider changing to another more effective method.
    let assetsMetadata = HM.HashMap<Nat, { mwh: T.TokenAmount; assetInfo: T.AssetInfo }>(16, Nat.equal, Hash.hash);

    switch(Serde.JSON.fromText(assetsJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize asset data");
      case(#ok(blob)) {
        let transactionResponse: ?[TransactionResponse] = from_candid(blob);
        var index: Nat = 0;

        switch(transactionResponse) {
          case(null) throw Error.reject("cannot serialize asset data");
          case(?response) {
            for({ items } in response.vals()) {
              for(itemResponse in items.vals()) {
                index := index + 1;

                assetsMetadata.put(index, {
                  mwh = await T.textToNat(itemResponse.volume);
                  assetInfo = await buildAssetInfo(itemResponse.assetDetails);
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

    let transactions = Iter.toArray(assetsMetadata.vals());

    if (transactions.size() > 0) {
      // update user portfolio
      await updatePortfolio(tokenHeader, Array.map<{
        mwh: T.TokenAmount;
        assetInfo: T.AssetInfo
      }, T.TokenId>(transactions, func x = x.assetInfo.tokenId)/* , { delete = false } */);
    };

    transactions
  };


  public shared({ caller }) func mintTokenToUser(recipent: T.BID, tokenId: T.TokenId, amount: T.TokenAmount): async T.TxIndex {
    _callValidation(caller);

    let assetsJson = await HttpService.get({
      url = HT.apiUrl # "assets/" # tokenId;
      port = null;
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

    // update user portfolio
    await updatePortfolio(await HT.tokenAuthFromUser(recipent), [tokenId]/* , { delete = false } */);

    txIndex
  };

  // helper function used to build [AssetInfo] from AssetResponse
  private func buildAssetInfo(asset: AssetResponse): async T.AssetInfo {
    let deviceType: T.AssetType = switch(asset.deviceType) {
      case("Solar") #Solar("Solar");
      case("Wind") #Wind("Wind");
      case("Hydro-Electric") #HydroElectric("Hydro-Electric");
      case("Thermal") #Thermal("Thermal");
      case _ #Other("Other");
    };

    {
      tokenId = asset.tokenId;
      startDate = asset.startDate;
      endDate = asset.endDate;
      co2Emission = asset.co2Emission;
      radioactivityEmnission = asset.radioactivityEmnission;
      volumeProduced = await T.textToNat(asset.volumeProduced);
      deviceDetails = {
        name = asset.name;
        deviceType;
        description = asset.description;
      };
      specifications = {
        deviceCode = asset.deviceCode;
        capacity = await T.textToNat(asset.capacity);
        location = asset.location;
        latitude = asset.latitude;
        longitude = asset.longitude;
        address = asset.address;
        stateProvince = asset.stateProvince;
        country = asset.country;
      };
      dates = asset.dates;
    };
  };

  // get token portfolio for a specific user
  public shared({ caller }) func getTokenPortfolio(uid: T.UID, tokenId: T.TokenId): async T.TokenInfo {
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

  /// get user portfolio
  public shared({ caller }) func getPortfolio(uid: T.UID, page: ?Nat, length: ?Nat, assetTypes: ?[T.AssetType], country: ?Text, mwhRange: ?[T.TokenAmount]): async {
    tokens: [T.TokenInfo];
    txIds: [T.TransactionId];
    totalPages: Nat;
  } {
    _callValidation(caller);

    // fetch user to get token ids
    let portfolioJson = await HttpService.get({
      url = HT.apiUrl # "users/portfolio";
      port = null;
      headers = [await HT.tokenAuthFromUser(uid)];
    });

    let portfolioIds: { tokenIds: [T.TokenId]; txIds: [T.TransactionId] } = switch(Serde.JSON.fromText(portfolioJson, null)) {
      case(#err(_)) throw Error.reject("cannot serialize asset data");
      case(#ok(blob)) {
        let portfolio: ?{ tokenIds: [T.TokenId]; txIds: [T.TransactionId] } = from_candid(blob);

        switch(portfolio) {
          case(null) throw Error.reject("cannot serialize asset data");
          case(?value) value;
        };
      };
    };

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


    for(tokenId in portfolioIds.tokenIds.vals()) {
      if (i >= startIndex and i < startIndex + maxLength) {
        switch(tokenDirectory.get(tokenId)) {
          case(null) {};

          case(?cid) {
            let token_balance = await Token.canister(cid).token_balance({ owner = uid; subaccount = null });
            let token = {
              tokenId;
              totalAmount = token_balance.balance;
              assetInfo = token_balance.assetMetadata;
              inMarket = 0;
            };

            // filter by tokenId
            let filterRange: Bool = switch(mwhRange) {
              case(null) true;
              case(?range) token.totalAmount >= range[0] and token.totalAmount <= range[1];
            };

            // filter by assetTypes
            let filterAssetType = switch (assetTypes) {
              case(null) true;
              case(?assets) {
                let assetType = Array.find<T.AssetType>(assets, func (assetType) { assetType == token.assetInfo.deviceDetails.deviceType });
                assetType != null
              };
            };

            // filter by country
            let filterCountry = switch (country) {
              case(null) true;
              case(?value) token.assetInfo.specifications.country == value;
            };

            if (token.totalAmount > 0 and filterRange and filterAssetType and filterCountry) tokens.add(token);
          };
        };
      };
      i += 1;
    };


    Debug.print(debug_show ("later getPortfolio: " # Nat.toText(Cycles.balance())));
    
    var totalPages: Nat = i / maxLength;
    if (totalPages <= 0) totalPages := 1;

    {
      tokens = Buffer.toArray<T.TokenInfo>(tokens);
      txIds = portfolioIds.txIds;
      totalPages;
    }
  };

  /// update user portfolio
  private func updatePortfolio(tokenHeader: { name: Text; value: Text; }, tokenIds: [T.TokenId]/* , { delete: Bool } */) : async() {

    let _ = await HttpService.post({
        url = HT.apiUrl # "users/portfolio";
        port = null;
        headers = [tokenHeader];
        bodyJson = switch(Serde.JSON.toText(to_candid({
          tokenIds;
        }), ["tokenIds"], null)) {
          case(#err(error)) throw Error.reject("Cannot serialize data");
          case(#ok(value)) value;
        };
      });
  };

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


  public shared({ caller }) func purchaseToken(buyer: T.UID, seller: T.BID, tokenId: T.TokenId, amount: T.TokenAmount, priceE8S: T.Price): async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
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

    // store token register on profile
    await updatePortfolio(await HT.tokenAuthFromUser(buyer), [tokenId]/* , { delete = false } */);

    txIndex
  };

  public shared ({ caller }) func requestRedeem(owner: T.UID, tokenId: T.TokenId, amount: T.TokenAmount, { returns: Bool }) : async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).requestRedeem({
        owner = {
          owner = owner;
          subaccount = null;
        };
        amount;
      }, { returns });
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

  public shared({ caller }) func redeemRequested(notification: T.NotificationInfo): async T.TxIndex {
    _callValidation(caller);

    let tokenId = switch(notification.tokenId) {
      case(null) throw Error.reject("tokenId not provided");
      case(?value) value;
    };
    let amount = switch(notification.quantity) {
      case(null) throw Error.reject("quantity not provided");
      case(?value) value;
    };

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).redeemRequested({
        owner = {
          owner = notification.receivedBy;
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

  public shared({ caller }) func redeem(owner: T.UID, tokenId: T.TokenId, amount: T.TokenAmount): async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).redeem({
        owner = {
          owner = owner;
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
}
