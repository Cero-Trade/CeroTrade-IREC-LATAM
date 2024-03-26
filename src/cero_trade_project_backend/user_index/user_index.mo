import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Types "../types";
import HttpServiceTypes "../http_service/http_service_types";

actor UserIndex {
  // TODO checkout this
  type UserId = Text;
  type CanisterId = Text;

  let userDict: HM.HashMap<Principal, Text> = HM.HashMap(16, Principal.equal, Principal.hash);


  public func registerUser(principal: Principal, userToken: Text) : async Principal {
    Principal.fromText("asdasd-asdasd");
  };

  public func getUserCanister(userPrincipal: Principal) : async Principal {
    Principal.fromText("asdasd-asdasd");
  };

  public func getUserToken(principal: Principal) : async Text {
    "asdasd";
  };

  public func getUserInfo(token: Text) : async Types.UserInfo {
    return {
      userID = 1;
      vaultToken = "Text";
      principal = Principal.fromText("asdasd-asdasd");
      redemptions = [];
      portfolio = [];
      transactions = [];
    }
  };

  public func checkPrincipal(principal: Principal) : async Types.UserInfo {
    return {
      userID = 1;
      vaultToken = "Text";
      principal = Principal.fromText("asdasd-asdasd");
      redemptions = [];
      portfolio = [];
      transactions = [];
    }
  }
}
