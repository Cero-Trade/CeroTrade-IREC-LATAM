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
import Debug "mo:base/Debug";

import ICRC1 "mo:icrc1-mo/ICRC1";

// canisters
import HttpService "canister:http_service";

// interfaces
import IC_MANAGEMENT "../ic_management_canister_interface";
import Token "../token/token_interface";

// types
import T "../types";
// import HT "../http_service/http_service_types";
import ENV "../env";

actor class TokenIndex() = this {
  stable var wasm_module: Blob = "";

  stable var controllers: ?[Principal] = null;

  var tokenDirectory: HM.HashMap<T.TokenId, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);
  stable var tokenDirectoryEntries : [(T.TokenId, T.CanisterId)] = [];


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
      await IC_MANAGEMENT.ic.install_code({
        arg = to_candid({
          name = await Token.canister(canister_id).icrc1_name();
          symbol = await Token.canister(canister_id).icrc1_symbol();
          logo = await Token.canister(canister_id).icrc1_logo();
          assetMetadata = await Token.canister(canister_id).assetMetadata();
        });
        wasm_module;
        mode = #upgrade;
        canister_id;
      });
    };
  };

  /// register [tokenDirectory] collection
  public shared({ caller }) func registerToken<system>(tokenId: Text, name: Text, symbol: Text, logo: Text): async T.CanisterId {
    _callValidation(caller);

    if (tokenId == "") throw Error.reject("Must to provide a tokenId");

    switch(tokenDirectory.get(tokenId)) {
      case(?value) throw Error.reject("Token already exists");
      case(null) {
        Debug.print(debug_show ("before registerToken: " # Nat.toText(Cycles.balance())));

        Cycles.add<system>(300_000_000_000);
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

        try {
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
              co2Emission = "11.22";
              radioactivityEmnission = "10.20";
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
                latitude = "0";
                longitude = "1";
                address = "address anywhere";
                stateProvince = "chile";
                country = "chile";
              };
              dates = ["2024-04-29T19:43:34.000Z", "2024-05-29T19:48:31.000Z", "2024-05-29T19:48:31.000Z"];
            };

          // install canister code
          await IC_MANAGEMENT.ic.install_code({
            arg = to_candid({ name; symbol; logo; assetMetadata });
            wasm_module;
            mode = #install;
            canister_id;
          });

          Debug.print(debug_show ("later install_canister: " # Nat.toText(Cycles.balance())));

          await Token.canister(canister_id).admin_init();

          tokenDirectory.put(tokenId, canister_id);
          return canister_id;
        } catch (error) {
          await IC_MANAGEMENT.ic.stop_canister({ canister_id });
          await IC_MANAGEMENT.ic.delete_canister({ canister_id });
          throw Error.reject(Error.message(error));
        };
      };
    };
  };

  /// delete [tokenDirectory] collection
  public shared({ caller }) func deleteToken<system>(tokenId: Text): async () {
    IC_MANAGEMENT.adminValidation(caller, controllers);

    switch(tokenDirectory.get(tokenId)) {
      case(null) throw Error.reject("Token doesn't exists");
      case(?canister_id) {
        Cycles.add<system>(20_949_972_000);
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
        Cycles.add<system>(20_949_972_000);
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
        Cycles.add<system>(20_949_972_000);
        await IC_MANAGEMENT.ic.start_canister({ canister_id });
      };
      case(null) {
        for(canister_id in tokenDirectory.vals()) {
          Cycles.add<system>(20_949_972_000);
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
        Cycles.add<system>(20_949_972_000);
        await IC_MANAGEMENT.ic.stop_canister({ canister_id });
      };
      case(null) {
        for(canister_id in tokenDirectory.vals()) {
          Cycles.add<system>(20_949_972_000);
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

  public shared({ caller }) func getAssetInfo(tokenId: T.TokenId): async T.AssetInfo {
    _callValidation(caller);

    switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found on cero trade");
      case (?cid) return await Token.canister(cid).assetMetadata();
    };
  };


  public shared({ caller }) func mintTokenToUser(recipent: T.Beneficiary, tokenId: T.TokenId, amount: T.TokenAmount): async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).icrc1_transfer({
        from_subaccount = null;
        to = {
          owner = recipent;
          subaccount = null;
        };
        amount;
        fee = null;
        memo = null;
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
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
      case (?cid) await Token.canister(cid).sellInMarketplace({
        seller;
        seller_subaccount = null;
        marketplace = {
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
      case (?cid) await Token.canister(cid).takeOffMarketplace({
        seller;
        seller_subaccount = null;
        marketplace = {
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


  public shared({ caller }) func purchaseToken(buyer: T.UID, seller: T.Beneficiary, tokenId: T.TokenId, amount: T.TokenAmount, priceE8S: T.Price): async T.TxIndex {
    _callValidation(caller);

    let transferResult: ICRC1.TransferResult = switch (tokenDirectory.get(tokenId)) {
      case (null) throw Error.reject("Token not found");
      case (?cid) await Token.canister(cid).purchaseInMarketplace({
        marketplace = Principal.fromText(ENV.CANISTER_ID_MARKETPLACE);
        seller = { owner = seller; subaccount = null };
        buyer = { owner = buyer; subaccount = null };
        amount;
        priceE8S;
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
