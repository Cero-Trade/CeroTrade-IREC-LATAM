import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
// import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import D "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";

import Principal "mo:base/Principal";
import Time "mo:base/Time";

// import CertifiedData "mo:base/CertifiedData";
import CertTree "mo:cert/CertTree";

import ICRC1 "mo:icrc1-mo/ICRC1";
import ICRC2 "mo:icrc2-mo/ICRC2";
import ICRC3 "mo:icrc3-mo/";
import ICRC4 "mo:icrc4-mo/ICRC4";

// types
import T "../types";
import ICPTypes "../ICPTypes";

shared ({ caller = _owner }) actor class Token(
  init_args : {
    name : Text;
    symbol : Text;
    logo : Text;
    assetMetadata : T.AssetInfo;
    comission : ICRC1.Balance;
    comissionHolder : ICPTypes.Account;
  }
) = this {
  private func _callValidation(caller : Principal) { assert _owner == caller };

  /// ICRC 1 args
  let icrc1_args : ICRC1.InitArgs = {
    name = ?init_args.name;
    symbol = ?init_args.symbol;
    logo = ?init_args.logo;
    decimals = T.tokenDecimals;
    fee = ? #Fixed(0);
    minting_account = ?{
      owner = _owner;
      subaccount = null;
    };
    max_supply = ?init_args.assetMetadata.volumeProduced;
    min_burn_amount = ?1;
    max_memo = ?64;
    advanced_settings = null;
    metadata = ? #Map([
      ("assetMetadata", #Map([
        ("assetId", #Text(init_args.assetMetadata.tokenId)),
        ("startDate", #Text(init_args.assetMetadata.startDate)),
        ("endDate", #Text(init_args.assetMetadata.endDate)),
        ("co2Emission", #Text(init_args.assetMetadata.co2Emission)),
        ("radioactivityEmission", #Text(init_args.assetMetadata.radioactivityEmission)),
        ("volumeProduced", #Nat(init_args.assetMetadata.volumeProduced)),
        ("deviceDetails", #Map([
          ("name", #Text(init_args.assetMetadata.deviceDetails.name)),
          ("deviceType", #Text(switch (init_args.assetMetadata.deviceDetails.deviceType) {
            case (#Solar(Solar)) Solar;
            case (#Wind(Wind)) Wind;
            case (#HydroElectric(HydroElectric)) HydroElectric;
            case (#Thermal(Thermal)) Thermal;
            case (#Other(Other)) Other;
          })),
          ("description", #Text(init_args.assetMetadata.deviceDetails.description))
        ])),
        ("specifications", #Map([
          ("deviceCode", #Text(init_args.assetMetadata.specifications.deviceCode)),
          ("location", #Text(init_args.assetMetadata.specifications.location)),
          ("latitude", #Text(init_args.assetMetadata.specifications.latitude)),
          ("longitude", #Text(init_args.assetMetadata.specifications.longitude)),
          ("country", #Text(init_args.assetMetadata.specifications.country))
        ]))
      ]))
    ]);
    fee_collector = null;
    transaction_window = null;
    permitted_drift = null;
    max_accounts = ?100000000;
    settle_to_accounts = ?99999000;
  };

  /// ICRC 2 args
  let icrc2_args : ICRC2.InitArgs = {
    max_approvals_per_account = ?10000;
    max_allowance = ? #TotalSupply;
    fee = ? #ICRC1;
    advanced_settings = null;
    max_approvals = ?10000000;
    settle_to_approvals = ?9990000;
  };

  /// ICRC 3 args
  let icrc3_args : ICRC3.InitArgs = ?{
    maxActiveRecords = 3000;
    settleToRecords = 2000;
    maxRecordsInArchiveInstance = 100000000;
    maxArchivePages = 62500;
    archiveIndexType = #Stable;
    maxRecordsToArchive = 8000;
    archiveCycles = 20_000_000_000_000;
    archiveControllers = null; //??[put cycle ops prinicpal here];
    supportedBlocks = [
      {
        block_type = "1xfer";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      },
      {
        block_type = "2xfer";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      },
      {
        block_type = "2approve";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      },
      {
        block_type = "1mint";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      },
      {
        block_type = "1burn";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      },
    ];
  };

  /// ICRC 4 args
  let icrc4_args : ICRC4.InitArgs = {
    max_balances = ?200;
    max_transfers = ?200;
    fee = ? #ICRC1;
  };

  stable let icrc1_migration_state = ICRC1.init(ICRC1.initialState(), #v0_1_0(#id), ?icrc1_args, _owner);
  stable let icrc2_migration_state = ICRC2.init(ICRC2.initialState(), #v0_1_0(#id), ?icrc2_args, _owner);
  stable let icrc4_migration_state = ICRC4.init(ICRC4.initialState(), #v0_1_0(#id), ?icrc4_args, _owner);
  stable let icrc3_migration_state = ICRC3.init(ICRC3.initialState(), #v0_1_0(#id), icrc3_args, _owner);
  stable let cert_store : CertTree.Store = CertTree.newStore();
  let ct = CertTree.Ops(cert_store);

  stable var owner = _owner;

  // let #v0_1_0(#data(_icrc1_state_current)) = icrc1_migration_state;

  private var _icrc1 : ?ICRC1.ICRC1 = null;

  // private func get_icrc1_state() : ICRC1.CurrentState {
  //   return icrc1_state_current;
  // };

  private func get_icrc1_environment() : ICRC1.Environment {
    {
      get_time = null;
      get_fee = null;
      add_ledger_transaction = ?icrc3().add_record;
      can_transfer = null; //set to a function to intercept and add validation logic for transfers
    };
  };

  func icrc1() : ICRC1.ICRC1 {
    switch (_icrc1) {
      case (null) {
        let initclass : ICRC1.ICRC1 = ICRC1.ICRC1(?icrc1_migration_state, Principal.fromActor(this), get_icrc1_environment());
        ignore initclass.register_supported_standards({
          name = "ICRC-3";
          url = "https://github.com/dfinity/ICRC/ICRCs/icrc-3/";
        });
        ignore initclass.register_supported_standards({
          name = "ICRC-10";
          url = "https://github.com/dfinity/ICRC/ICRCs/icrc-10/";
        });
        _icrc1 := ?initclass;
        initclass;
      };
      case (?val) val;
    };
  };

  // let #v0_1_0(#data(_icrc2_state_current)) = icrc2_migration_state;

  private var _icrc2 : ?ICRC2.ICRC2 = null;

  // private func get_icrc2_state() : ICRC2.CurrentState {
  //   return icrc2_state_current;
  // };

  private func get_icrc2_environment() : ICRC2.Environment {
    {
      icrc1 = icrc1();
      get_fee = null;
      can_approve = null; //set to a function to intercept and add validation logic for approvals
      can_transfer_from = null; //set to a function to intercept and add validation logic for transfer froms
    };
  };

  func icrc2() : ICRC2.ICRC2 {
    switch (_icrc2) {
      case (null) {
        let initclass : ICRC2.ICRC2 = ICRC2.ICRC2(?icrc2_migration_state, Principal.fromActor(this), get_icrc2_environment());
        _icrc2 := ?initclass;
        initclass;
      };
      case (?val) val;
    };
  };

  // let #v0_1_0(#data(_icrc4_state_current)) = icrc4_migration_state;

  private var _icrc4 : ?ICRC4.ICRC4 = null;

  // private func get_icrc4_state() : ICRC4.CurrentState {
  //   return icrc4_state_current;
  // };

  private func get_icrc4_environment() : ICRC4.Environment {
    {
      icrc1 = icrc1();
      get_fee = null;
      can_approve = null; //set to a function to intercept and add validation logic for approvals
      can_transfer_from = null; //set to a function to intercept and add validation logic for transfer froms
    };
  };

  func icrc4() : ICRC4.ICRC4 {
    switch (_icrc4) {
      case (null) {
        let initclass : ICRC4.ICRC4 = ICRC4.ICRC4(?icrc4_migration_state, Principal.fromActor(this), get_icrc4_environment());
        _icrc4 := ?initclass;
        initclass;
      };
      case (?val) val;
    };
  };

  // let #v0_1_0(#data(_icrc3_state_current)) = icrc3_migration_state;

  private var _icrc3 : ?ICRC3.ICRC3 = null;

  // private func get_icrc3_state() : ICRC3.CurrentState {
  //   return icrc3_state_current;
  // };

  // func _get_state() : ICRC3.CurrentState{
  //   return icrc3_state_current;
  // };

  private func get_icrc3_environment() : ICRC3.Environment {
    ?{
      updated_certification = ?updated_certification;
      get_certificate_store = ?get_certificate_store;
    };
  };

  func ensure_block_types(icrc3Class : ICRC3.ICRC3) : () {
    let supportedBlocks = Buffer.fromIter<ICRC3.BlockType>(icrc3Class.supported_block_types().vals());

    let blockequal = func(a : { block_type : Text }, b : { block_type : Text }) : Bool {
      a.block_type == b.block_type;
    };

    if (Buffer.indexOf<ICRC3.BlockType>({ block_type = "1xfer"; url = "" }, supportedBlocks, blockequal) == null) {
      supportedBlocks.add({
        block_type = "1xfer";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      });
    };

    if (Buffer.indexOf<ICRC3.BlockType>({ block_type = "2xfer"; url = "" }, supportedBlocks, blockequal) == null) {
      supportedBlocks.add({
        block_type = "2xfer";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      });
    };

    if (Buffer.indexOf<ICRC3.BlockType>({ block_type = "2approve"; url = "" }, supportedBlocks, blockequal) == null) {
      supportedBlocks.add({
        block_type = "2approve";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      });
    };

    if (Buffer.indexOf<ICRC3.BlockType>({ block_type = "1mint"; url = "" }, supportedBlocks, blockequal) == null) {
      supportedBlocks.add({
        block_type = "1mint";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      });
    };

    if (Buffer.indexOf<ICRC3.BlockType>({ block_type = "1burn"; url = "" }, supportedBlocks, blockequal) == null) {
      supportedBlocks.add({
        block_type = "1burn";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-3";
      });
    };

    icrc3Class.update_supported_blocks(Buffer.toArray(supportedBlocks));
  };

  func icrc3() : ICRC3.ICRC3 {
    switch (_icrc3) {
      case (null) {
        let initclass : ICRC3.ICRC3 = ICRC3.ICRC3(?icrc3_migration_state, Principal.fromActor(this), get_icrc3_environment());
        _icrc3 := ?initclass;
        ensure_block_types(initclass);

        initclass;
      };
      case (?val) val;
    };
  };

  private func updated_certification(_cert : Blob, _lastIndex : Nat) : Bool {

    // D.print("updating the certification " # debug_show(CertifiedData.getCertificate(), ct.treeHash()));
    ct.setCertifiedData();
    // D.print("did the certification " # debug_show(CertifiedData.getCertificate()));
    return true;
  };

  private func get_certificate_store() : CertTree.Store {
    // D.print("returning cert store " # debug_show(cert_store));
    return cert_store;
  };

  public shared query func icrc1_logo() : async Text {
    init_args.logo;
  };

  public shared query func tx_comission() : async ICRC1.Balance {
    init_args.comission;
  };

  /// Functions for the ICRC1 token standard
  public shared query func icrc1_name() : async Text {
    icrc1().name();
  };

  public shared query func icrc1_symbol() : async Text {
    icrc1().symbol();
  };

  public shared query func icrc1_decimals() : async Nat8 {
    icrc1().decimals();
  };

  public shared query func icrc1_fee() : async ICRC1.Balance {
    icrc1().fee();
  };

  public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
    icrc1().metadata();
  };

  public shared query func assetMetadata() : async T.AssetInfo {
    let metadata = Buffer.fromArray<ICRC1.MetaDatum>(icrc1().metadata());
    let assetMetadata = metadata.get(0).1;

    // build asset metadata instance
    switch (assetMetadata) {
      case (#Map(map)) {
        return {
          tokenId = switch (map.get(0).1) {
            case (#Text(text)) text;
            case (_) throw Error.reject("cannot find assetMetadata");
          };
          startDate = switch (map.get(1).1) {
            case (#Text(text)) text;
            case (_) throw Error.reject("cannot find assetMetadata");
          };
          endDate = switch (map.get(2).1) {
            case (#Text(text)) text;
            case (_) throw Error.reject("cannot find assetMetadata");
          };
          co2Emission = switch (map.get(3).1) {
            case (#Text(text)) text;
            case (_) throw Error.reject("cannot find assetMetadata");
          };
          radioactivityEmission = switch (map.get(4).1) {
            case (#Text(text)) text;
            case (_) throw Error.reject("cannot find assetMetadata");
          };
          volumeProduced = switch (map.get(5).1) {
            case (#Nat(nat)) nat;
            case (_) throw Error.reject("cannot find assetMetadata");
          };
          deviceDetails = {
            name = switch (map.get(6).1) {
              case (#Map(childMap)) {
                switch (childMap.get(0).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
            deviceType = switch (map.get(6).1) {
              case (#Map(childMap)) {
                switch (childMap.get(1).1) {
                  case (#Text(text)) {
                    switch (text) {
                      case("Solar") #Solar("Solar");
                      case("Wind") #Wind("Wind");
                      case("Hydro-Electric") #HydroElectric("Hydro-Electric");
                      case("Thermal") #Thermal("Thermal");
                      case _ #Other("Other");
                    };
                  };
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
            description = switch (map.get(6).1) {
              case (#Map(childMap)) {
                switch (childMap.get(2).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
          };
          specifications = {
            deviceCode = switch (map.get(7).1) {
              case (#Map(childMap)) {
                switch (childMap.get(0).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
            location = switch (map.get(7).1) {
              case (#Map(childMap)) {
                switch (childMap.get(1).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
            latitude = switch (map.get(7).1) {
              case (#Map(childMap)) {
                switch (childMap.get(2).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
            longitude = switch (map.get(7).1) {
              case (#Map(childMap)) {
                switch (childMap.get(3).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
            country = switch (map.get(7).1) {
              case (#Map(childMap)) {
                switch (childMap.get(4).1) {
                  case (#Text(text)) text;
                  case (_) throw Error.reject("cannot find assetMetadata");
                };
              };
              case (_) throw Error.reject("cannot find assetMetadata");
            };
          };
        };
      };
      case (_) throw Error.reject("cannot find assetMetadata");
    };
  };

  public shared query func icrc1_total_supply() : async ICRC1.Balance {
    icrc1().total_supply();
  };

  public shared query func icrc1_minting_account() : async ?ICRC1.Account {
    ?icrc1().minting_account();
  };

  public shared query func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance {
    icrc1().balance_of(args);
  };

  public shared func token_balance(args : ICRC1.Account) : async {
    balance : ICRC1.Balance;
    assetMetadata : T.AssetInfo;
  } {
    {
      balance = icrc1().balance_of(args);
      assetMetadata = await assetMetadata();
    };
  };

  public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
    icrc1().supported_standards();
  };

  public shared query func icrc10_supported_standards() : async [ICRC1.SupportedStandard] {
    icrc1().supported_standards();
  };

  public shared ({ caller }) func transfer(args : ICRC1.TransferArgs) : async T.TokenTxResponse {
    // performe comission
    let comission_block = switch (await ICPTypes.ICPLedger.icrc2_transfer_from({ from = { owner = caller; subaccount = null }; to = init_args.comissionHolder; fee = null; spender_subaccount = null; memo = null; created_at_time = ?time64(); amount = init_args.comission })) {
      case (#Ok(block)) block;
      case (#Err(err)) {
        D.trap("cannot performe comission from failed" # debug_show (err));
      };
    };

    // transfer tokens
    let txResult = switch (await* icrc1().transfer_tokens(caller, args, false, null)) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };

    {
      comission_block;
      token_result = txResult;
    }
  };

  public shared ({ caller }) func mint(args : ICRC1.Mint) : async T.TokenTxResponse {
    if (caller != owner) { D.trap("Unauthorized") };

    let txResult = switch (await* icrc1().mint_tokens(caller, args)) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };

    // performe comission to register block into ledger
    let comission_block = switch (await ICPTypes.ICPLedger.icrc2_transfer_from({ from = init_args.comissionHolder; to = { owner = _owner; subaccount = null; }; fee = null; spender_subaccount = null; memo = null; created_at_time = ?time64(); amount = 1 })) {
      case (#Ok(block)) block;
      case (#Err(err)) {
        D.trap("cannot performe comission from failed" # debug_show (err));
      };
    };

    {
      comission_block;
      token_result = txResult;
    }
  };

  private func time64() : Nat64 {
    Nat64.fromNat(Int.abs(Time.now()));
  };

  public shared ({ caller }) func transferInMarketplace(args : T.TransferInMarketplaceArgs) : async ICRC1.TransferResult {
    _callValidation(caller);

    switch (
      await* icrc1().transfer_tokens(
        args.from.owner,
        {
          from_subaccount = switch (args.from.subaccount) {
            case (null) null;
            case (?value) ?Blob.fromArray(value);
          };
          to = {
            owner = args.to.owner;
            subaccount = switch (args.to.subaccount) {
              case (null) null;
              case (?value) ?Blob.fromArray(value);
            };
          };
          amount = args.amount;
          fee = null;
          memo = null;
          /// The time at which the transaction was created.
          /// If this is set, the canister will check for duplicate transactions and reject them.
          created_at_time = ?time64();
        },
        false,
        null,
      )
    ) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };
  };

  public shared ({ caller }) func requestRedeem(args : T.RedeemArgs, { returns: Bool }) : async ICRC1.TransferResult {
    _callValidation(caller);

    let user = {
      owner = args.owner.owner;
      subaccount = switch (args.owner.subaccount) {
        case (null) null;
        case (?value) ?Blob.fromArray(value);
      }
    };
    let canister = {
      owner = Principal.fromActor(this);
      subaccount = null;
    };

    let from = switch(returns) {
      case(false) user;
      case(true) canister;
    };
    let to = switch(returns) {
      case(false) canister;
      case(true) user;
    };

    switch (
      await* icrc1().transfer_tokens(
        from.owner,
        {
          from_subaccount = from.subaccount;
          to;
          amount = args.amount;
          fee = null;
          memo = null;
          /// The time at which the transaction was created.
          /// If this is set, the canister will check for duplicate transactions and reject them.
          created_at_time = ?time64();
        },
        false,
        null,
      )
    ) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };
  };

  public shared ({ caller }) func redeemRequested(args : T.RedeemArgs) : async T.TokenTxResponse {
    _callValidation(caller);

    // performe comission
    let comission_block = switch (await ICPTypes.ICPLedger.icrc2_transfer_from({ from = args.owner; to = init_args.comissionHolder; fee = null; spender_subaccount = null; memo = null; created_at_time = ?time64(); amount = init_args.comission })) {
      case (#Ok(block)) block;
      case (#Err(err)) {
        D.trap("cannot performe comission from failed" # debug_show (err));
      };
    };

    let txResult = switch (
      await* icrc1().burn_tokens(
        Principal.fromActor(this),
        {
          from_subaccount = null;
          amount = args.amount;
          memo = null;
          created_at_time = ?time64();
        },
        false,
      )
    ) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };

    {
      comission_block;
      token_result = txResult;
    }
  };

  public shared ({ caller }) func redeem(args : T.RedeemArgs) : async T.TokenTxResponse {
    _callValidation(caller);

    // performe comission
    let comission_block = switch (await ICPTypes.ICPLedger.icrc2_transfer_from({ from = args.owner; to = init_args.comissionHolder; fee = null; spender_subaccount = null; memo = null; created_at_time = ?time64(); amount = init_args.comission })) {
      case (#Ok(block)) block;
      case (#Err(err)) {
        D.trap("cannot performe comission from failed" # debug_show (err));
      };
    };

    let txResult = switch (
      await* icrc1().burn_tokens(
        args.owner.owner,
        {
          from_subaccount = switch (args.owner.subaccount) {
            case (null) null;
            case (?value) ?Blob.fromArray(value);
          };
          amount = args.amount;
          memo = null;
          created_at_time = ?time64();
        },
        false,
      )
    ) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };

    {
      comission_block;
      token_result = txResult;
    }
  };

  public shared ({ caller }) func burnUserTokens(args : T.RedeemArgs) : async ICRC1.TransferResult {
    _callValidation(caller);

    switch (
      await* icrc1().burn_tokens(
        args.owner.owner,
        {
          from_subaccount = switch (args.owner.subaccount) {
            case (null) null;
            case (?value) ?Blob.fromArray(value);
          };
          amount = args.amount;
          memo = null;
          created_at_time = ?time64();
        },
        false,
      )
    ) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };
  };

  public shared ({ caller }) func purchaseInMarketplace(args : T.PurchaseInMarketplaceArgs) : async T.PurchaseTxResponse {
    _callValidation(caller);

    // performe comission
    let comission_block = switch (await ICPTypes.ICPLedger.icrc2_transfer_from({ from = args.buyer; to = init_args.comissionHolder; fee = null; spender_subaccount = null; memo = null; created_at_time = ?time64(); amount = init_args.comission })) {
      case (#Ok(block)) block;
      case (#Err(err)) {
        D.trap("cannot performe comission from failed" # debug_show (err));
      };
    };

    // transfer icp token
    let result = try {
      await ICPTypes.ICPLedger.icrc2_transfer_from({
        to = args.seller;
        from = args.buyer;
        fee = null;
        spender_subaccount = null;
        memo = null;
        created_at_time = ?time64();
        amount = Nat64.toNat(args.priceE8S.e8s);
      });
    } catch (e) {
      D.trap("cannot transfer from failed" # Error.message(e));
    };

    let ledger_block = switch (result) {
      case (#Ok(block)) block;
      case (#Err(err)) {
        D.trap("cannot transfer from failed" # debug_show (err));
      };
    };

    // transfer canister token
    let txResult = switch (
      await* icrc1().transfer_tokens(
        args.marketplace.owner,
        {
          from_subaccount = switch (args.marketplace.subaccount) {
            case (null) null;
            case (?value) ?Blob.fromArray(value);
          };
          to = {
            owner = args.buyer.owner;
            subaccount = switch (args.buyer.subaccount) {
              case (null) null;
              case (?value) ?Blob.fromArray(value);
            };
          };
          amount = args.amount;
          fee = null;
          memo = null;
          /// The time at which the transaction was created.
          /// If this is set, the canister will check for duplicate transactions and reject them.
          created_at_time = ?time64();
        },
        false,
        null,
      )
    ) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };

    {
      comission_block;
      ledger_block;
      token_result = (txResult, await assetMetadata());
    }
  };

  public shared ({ caller }) func burn(args : ICRC1.BurnArgs) : async ICRC1.TransferResult {
    switch (await* icrc1().burn_tokens(caller, args, false)) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };
  };

  public query func icrc2_allowance(args : ICRC2.AllowanceArgs) : async ICRC2.Allowance {
    return icrc2().allowance(args.spender, args.account, false);
  };

  public shared ({ caller }) func icrc2_approve(args : ICRC2.ApproveArgs) : async ICRC2.ApproveResponse {
    switch (await* icrc2().approve_transfers(caller, args, false, null)) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };
  };

  public shared ({ caller }) func icrc2_transfer_from(args : ICRC2.TransferFromArgs) : async ICRC2.TransferFromResponse {
    switch (await* icrc2().transfer_tokens_from(caller, args, null)) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) D.trap(err);
      case (#err(#awaited(err))) D.trap(err);
    };
  };

  public query func icrc3_get_blocks(args : ICRC3.GetBlocksArgs) : async ICRC3.GetBlocksResult {
    return icrc3().get_blocks(args);
  };

  public query func icrc3_get_archives(args : ICRC3.GetArchivesArgs) : async ICRC3.GetArchivesResult {
    return icrc3().get_archives(args);
  };

  public query func icrc3_get_tip_certificate() : async ?ICRC3.DataCertificate {
    return icrc3().get_tip_certificate();
  };

  public query func icrc3_supported_block_types() : async [ICRC3.BlockType] {
    return icrc3().supported_block_types();
  };

  public query func get_tip() : async ICRC3.Tip {
    return icrc3().get_tip();
  };

  public shared ({ caller }) func icrc4_transfer_batch(args : ICRC4.TransferBatchArgs) : async ICRC4.TransferBatchResults {
    switch (await* icrc4().transfer_batch_tokens(caller, args, null, null)) {
      case (#trappable(val)) val;
      case (#awaited(val)) val;
      case (#err(#trappable(err))) err;
      case (#err(#awaited(err))) err;
    };
  };

  public shared query func icrc4_balance_of_batch(request : ICRC4.BalanceQueryArgs) : async ICRC4.BalanceQueryResult {
    icrc4().balance_of_batch(request);
  };

  public shared query func icrc4_maximum_update_batch_size() : async ?Nat {
    ?icrc4().get_state().ledger_info.max_transfers;
  };

  public shared query func icrc4_maximum_query_batch_size() : async ?Nat {
    ?icrc4().get_state().ledger_info.max_balances;
  };

  public shared ({ caller }) func admin_update_owner(new_owner : Principal) : async Bool {
    if (caller != owner) { D.trap("Unauthorized") };
    owner := new_owner;
    return true;
  };

  public shared ({ caller }) func admin_update_icrc1(requests : [ICRC1.UpdateLedgerInfoRequest]) : async [Bool] {
    if (caller != owner) { D.trap("Unauthorized") };
    return icrc1().update_ledger_info(requests);
  };

  public shared ({ caller }) func admin_update_icrc2(requests : [ICRC2.UpdateLedgerInfoRequest]) : async [Bool] {
    if (caller != owner) { D.trap("Unauthorized") };
    return icrc2().update_ledger_info(requests);
  };

  public shared ({ caller }) func admin_update_icrc4(requests : [ICRC4.UpdateLedgerInfoRequest]) : async [Bool] {
    if (caller != owner) { D.trap("Unauthorized") };
    return icrc4().update_ledger_info(requests);
  };

  /* /// Uncomment this code to establish have icrc1 notify you when a transaction has occured.
  private func transfer_listener(trx: ICRC1.Transaction, trxid: Nat) : () {

  };

  /// Uncomment this code to establish have icrc1 notify you when a transaction has occured.
  private func approval_listener(trx: ICRC2.TokenApprovalNotification, trxid: Nat) : () {

  };

  /// Uncomment this code to establish have icrc1 notify you when a transaction has occured.
  private func transfer_from_listener(trx: ICRC2.TransferFromNotification, trxid: Nat) : () {

  }; */

  private stable var _init = false;
  public func admin_init() : async () {
    //can only be called once

    if (_init == false) {
      //ensure metadata has been registered
      let _test1 = icrc1().metadata();
      let _test2 = icrc2().metadata();
      let _test4 = icrc4().metadata();
      let _test3 = icrc3().stats();

      //uncomment the following line to register the transfer_listener
      //icrc1().register_token_transferred_listener("my_namespace", transfer_listener);

      //uncomment the following line to register the transfer_listener
      //icrc2().register_token_approved_listener("my_namespace", approval_listener);

      //uncomment the following line to register the transfer_listener
      //icrc1().register_transfer_from_listener("my_namespace", transfer_from_listener);
    };
    _init := true;
  };

  // Deposit cycles into this canister.
  public shared func deposit_cycles() : async () {
    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept<system>(amount);
    assert (accepted == amount);
  };

  system func postupgrade() {
    //re wire up the listener after upgrade
    //uncomment the following line to register the transfer_listener
    //icrc1().register_token_transferred_listener("my_namespace", transfer_listener);

    //uncomment the following line to register the transfer_listener
    //icrc2().register_token_approved_listener("my_namespace", approval_listener);

    //uncomment the following line to register the transfer_listener
    //icrc1().register_transfer_from_listener("my_namespace", transfer_from_listener);
  };

};
