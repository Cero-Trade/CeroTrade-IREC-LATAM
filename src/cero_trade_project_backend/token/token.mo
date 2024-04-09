import HM = "mo:base/HashMap";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

// canisters
import HttpService "canister:http_service";
import Users "canister:users";

// types
import ICRC "../ICRC";
import T "../types";
import HT "../http_service/http_service_types";


actor class Token(_tokenId: ?T.TokenId) = this {
  stable let tokenId = switch (_tokenId) {
    case (null) "0";
    case (?value) value;
  };
  private stable var isInitialized: Bool = false;

  /// asset metadata
  stable var assetInfo: ?T.AssetInfo = null;
  stable var leftToMint: Nat = 0;

  stable let userNotFound: Text = "User not found";

  let irecs: HM.HashMap<T.UID, Nat> = HM.HashMap(16, Principal.equal, Principal.hash);


  public shared ({ caller }) func init(): async T.CanisterId {
    // if (init_msg.caller != caller) throw Error.reject("Unauthorized call");
    if (isInitialized) throw Error.reject("Canister has been initialized");

    /// fetch asset info using [tokenId]
    // let asset = await HttpService.get("getToken" # tokenId, { headers = [] });

    let volumeProduced = 1000;

    assetInfo := ?{
      assetType = "hydroenergy";
      startDate = 2222;
      endDate = 22222;
      co2Emission = 100;
      radioactivityEmnission = 10;
      volumeProduced = volumeProduced;
      deviceDetails = {
        name = "machine";
        deviceType = "type";
        group = "hydroenergy"; // AssetType
        description = "description";
      };
      specifications = {
        deviceCode = "200";
        capacity = 1000;
        location = "location";
        latitude = 0;
        longitude = 1;
        address = "address anywhere";
        stateProvince = "texas";
        country = "texas";
      };
      dates = [123321, 123123];
    };
    leftToMint := volumeProduced;

    isInitialized := true;

    Principal.fromActor(this)
  };



  /// add token to collection
  public func mintToken(uid: T.UID, amount: Nat) : async () {
    if (leftToMint < amount) throw Error.reject("Limit tokens to mint is" # Nat.toText(leftToMint));

    /// update leftToMint amount info
    leftToMint := leftToMint - amount;

    // update user into irecs
    let mintedAmount = switch(irecs.get(uid)) {
      case(?currentAmount) currentAmount + amount;
      case(null) amount;
    };
    irecs.put(uid, mintedAmount);

    await Users.updatePorfolio(uid, {
      tokenId = tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = amount;
      inMarket = mintedAmount; // TODO evaluate what value use
    });
  };


  public func burn(uid: T.UID, amount: Nat): async () {
    let burnedAmount: Nat = switch(irecs.get(uid)) {
      case(null) throw Error.reject(userNotFound);
      case(?currentAmount) currentAmount - amount;
    };

    irecs.put(uid, burnedAmount);

    await Users.updatePorfolio(uid, {
      tokenId = tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = amount;
      inMarket = burnedAmount; // TODO evaluate what value use
    });
  };


  public query func getUserMinted(uid: T.UID): async Nat {
    switch(irecs.get(uid)) {
      case(null) throw Error.reject(userNotFound);
      case(?irecMinted) irecMinted;
    };
  };



  public func getAssetInfo(): async T.AssetInfo {
    switch(assetInfo) {
      case(null) { throw Error.reject("Asset metadata have not generated") };
      case(?value) return value;
    };
  };

  public query func getRemainingAmount(): async Nat { leftToMint };
  
  public query func getTokenId(): async T.TokenId { tokenId };

  public query func getCanisterId(): async T.CanisterId { Principal.fromActor(this) };
}
