import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import HttpService "canister:http_service";
import HttpTypes "../http_service/http_service_types";
import Types "../types";

actor Agent {
  let apiUrl = "https://api.cerotrade.cl/";

  public func register(principal: Principal) : async HttpTypes.Result<Text, Text> {
    try {
      let response = await HttpService.post(apiUrl # "api/user/store", {
          headers = [];
          // TODO checkout this
          // TODO assign userInfoJson()
          bodyJson = "{\"principal\":\"" # Principal.toText(principal) # "\",\"userInfo\":\"" # "Types.userInfoJson()" # "\"}"
        });
      #ok response;
    } catch (error) {
      let errorText = Error.message(error);
      #err errorText;
    };
  }
}
