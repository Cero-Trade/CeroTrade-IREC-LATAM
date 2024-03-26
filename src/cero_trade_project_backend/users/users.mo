import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Types "../types";

actor Users {
  let users: HM.HashMap<Principal, Text> = HM.HashMap(16, Principal.equal, Principal.hash);


  // TODO checkout this
  public func getUserInfo(vaultToken: Text) : async Types.UserInfo {
    return {
      userID = 1;
      vaultToken = "Text";
      principal = Principal.fromText("asdasd-asdasd");
      redemptions = [];
      portfolio = [];
      transactions = [];
    }
  };

  public func getUserIndexCanisterID(principal: Principal) : async Principal {
    Principal.fromText("asdasd-asdasd");
  }
}
