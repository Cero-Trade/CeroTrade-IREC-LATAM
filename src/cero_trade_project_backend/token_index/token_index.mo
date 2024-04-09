import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Error "mo:base/Error";

// canisters
import Token "canister:token";

// types
import T "../types";

actor TokenIndex {
  let tokenLocation: HM.HashMap<Text, T.CanisterId> = HM.HashMap(16, Text.equal, Text.hash);


  /// get size of tokenLocation collection
  public query func length(): async Nat {
    tokenLocation.size();
  };


  /// register [tokenLocation] collection
  public func initToken(tokenId: T.TokenId) : async() {
    if (tokenId == "") throw Error.reject("Must to provide a tokenId")
    else if (tokenLocation.get(tokenId) != null) throw Error.reject("Token already exists");

    // TODO evaluate how to search specific canister to call init func
    let cid = await Token.init();
    tokenLocation.put(tokenId, cid);
  };


  /// get canister id that allow current user
  public query func getTokenCanister(token: T.TokenId) : async T.CanisterId {
    switch (tokenLocation.get(token)) {
      case (null) { throw Error.reject("Token not found"); };
      case (?cid) { return cid };
    };
  };


  public func mintToken(uid: T.UID, tokenId: T.TokenId, amount: Nat): async() {
    if (tokenLocation.get(tokenId) == null) throw Error.reject("Token doesn't exists");

    // TODO evaluate how to search specific canister to call mintToken func
    await Token.mintToken(uid, amount);
  }
}
