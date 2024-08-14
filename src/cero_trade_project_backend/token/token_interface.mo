import Principal "mo:base/Principal";

import ICRC1 "mo:icrc1-mo/ICRC1";
import ICRC2 "mo:icrc2-mo/ICRC2";
import ICRC3 "mo:icrc3-mo/";
import ICRC4 "mo:icrc4-mo/ICRC4";

// types
import T "../types"

module TokenInterface {
  public func canister(cid: Principal): Token { actor (Principal.toText(cid)) };

  public type Token = actor {
    icrc1_name: query () -> async Text;
    icrc1_logo: query () -> async Text;
    icrc1_symbol: query () -> async Text;
    icrc1_decimals: query () -> async Nat8;
    icrc1_fee: query () -> async ICRC1.Balance;
    icrc1_metadata: query () -> async [ICRC1.MetaDatum];
    assetMetadata: query () -> async T.AssetInfo;
    icrc1_total_supply: query () -> async ICRC1.Balance;
    icrc1_minting_account: query () -> async ?ICRC1.Account;
    icrc1_balance_of: query (args: ICRC1.Account) -> async ICRC1.Balance;
    token_balance: (args: ICRC1.Account) -> async { balance: ICRC1.Balance; assetMetadata: T.AssetInfo; };
    icrc1_supported_standards: query () -> async [ICRC1.SupportedStandard];
    icrc10_supported_standards: query () -> async [ICRC1.SupportedStandard];
    icrc1_transfer: (args: ICRC1.TransferArgs) -> async ICRC1.TransferResult;
    mint: (args: ICRC1.Mint) -> async ICRC1.TransferResult;
    transferInMarketplace: (args : T.TransferInMarketplaceArgs) -> async ICRC1.TransferResult;
    purchaseInMarketplace: (args : T.PurchaseInMarketplaceArgs) -> async ICRC1.TransferResult;
    requestRedeem: (args : T.RedeemArgs, { returns: Bool }) -> async ICRC1.TransferResult;
    redeemRequested: (args : T.RedeemArgs) -> async ICRC1.TransferResult;
    redeem: (args : T.RedeemArgs) -> async ICRC1.TransferResult;
    burn: (args: ICRC1.BurnArgs) -> async ICRC1.TransferResult;
    icrc2_allowance: query (args: ICRC2.AllowanceArgs) -> async ICRC2.Allowance;
    icrc2_approve: (args: ICRC2.ApproveArgs) -> async ICRC2.ApproveResponse;
    icrc2_transfer_from: (args: ICRC2.TransferFromArgs) -> async ICRC2.TransferFromResponse;
    // icrc3_get_blocks: query (args: ICRC3.GetBlocksArgs) -> async ICRC3.GetBlocksResul;
    // icrc3_get_archives: query (args: ICRC3.GetArchivesArgs) -> async ICRC3.GetArchivesResul;
    icrc3_get_tip_certificate: query () -> async ?ICRC3.DataCertificate;
    icrc3_supported_block_types: query () -> async [ICRC3.BlockType];
    get_tip: query () -> async ICRC3.Tip;
    icrc4_transfer_batch: (args: ICRC4.TransferBatchArgs) -> async ICRC4.TransferBatchResults;
    icrc4_balance_of_batch: query (request: ICRC4.BalanceQueryArgs) -> async ICRC4.BalanceQueryResult;
    icrc4_maximum_update_batch_size: query () -> async ?Nat;
    icrc4_maximum_query_batch_size: query () -> async ?Nat;
    admin_update_owner: (new_owner: Principal) -> async Bool;
    admin_update_icrc1: (requests: [ICRC1.UpdateLedgerInfoRequest]) -> async [Bool];
    admin_update_icrc2: (requests: [ICRC2.UpdateLedgerInfoRequest]) -> async [Bool];
    admin_update_icrc4: (requests: [ICRC4.UpdateLedgerInfoRequest]) -> async [Bool];
    admin_init: () -> async ();
    deposit_cycles: () -> async ();
    tx_comission: () -> async ICRC1.Balance;
  };
}