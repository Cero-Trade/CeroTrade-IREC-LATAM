import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Int "mo:base/Int";

module {
  public type UID = Principal;
  public type CanisterID = Principal;

  public type UserInfo = {
    userID: Nat;
    vaultToken: Text;
    principal: Principal;
    redemptions: [RedemInfo];
    portfolio: [TokenList];
    transactions: [TransactionInfo];
  };

  public func createUserInfo(uid: UID, token: Text, id: Nat): UserInfo {
    {
      userID = id;
      vaultToken = token;
      principal = uid;
      redemptions = [];
      portfolio = [];
      transactions = [];
    }
  };

  public func userInfoJson(userInfo: UserInfo) : Text {
    let principalText = Principal.toText(userInfo.principal);
    // TODO checkout how to stringnify this content of array
    let redemptions = "[]";
    let portfolio = "[]";
    let transactions = "[]";

    "{ \"userID\": \"" # Nat.toText(userInfo.userID) # "\", \"vaultToken\": \"" # userInfo.vaultToken # "\", \"principal\": \"" # principalText # "\", \"redemptions\": \"" # redemptions # "\", \"portfolio\": \"" # portfolio # "\", \"transactions\": \"" # transactions # "\" }";
  };


  public type TokenList = {
    tokenID: Text;
    totalAmount: Nat;
    inMarket: Nat;
  };
  
  public func tokenListJson(tokenList: TokenList) : Text {
    return "{{ \"tokenID\": \"" # tokenList.tokenID # "\", \"totalAmount\": \"" # Nat.toText(tokenList.totalAmount) # "\", \"inMarket\": \"" # Nat.toText(tokenList.inMarket) # "\" }}";
  };

  
  public type RedemInfo = {
    tokenID: Text;
    redAmount: Nat;
  };
  
  public func redemInfoJson(redemInfo: RedemInfo) : Text {
    return "{{ \"tokenID\": \"" # redemInfo.tokenID # "\", \"redAmount\": \"" # Nat.toText(redemInfo.redAmount) # "\" }}";
  };


  public type TransactionInfo = {
    tokenID: Text;
    txType: Text;
    source: Text;
    country: Text;
    mwh: Text;
    assetID: Text;
    date: Int;
  };
  
  public func transactionInfo(transactionInfo: TransactionInfo) : Text {
    return "{{ \"tokenID\": \"" # transactionInfo.tokenID # "\", \"txType\": \"" # transactionInfo.txType # "\", \"source\": \"" # transactionInfo.source # "\", \"country\": \"" # transactionInfo.country # "\", \"mwh\": \"" # transactionInfo.mwh # "\", \"assetID\": \"" # transactionInfo.assetID # "\", \"date\": \"" # Int.toText(transactionInfo.date) # "\" }}";
  };
}
