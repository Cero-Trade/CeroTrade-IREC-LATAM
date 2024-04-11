import HM = "mo:base/HashMap";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

// types
import ICRC "../ICRC";
import T "../types";


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


  public func init(assetMetadata: T.AssetInfo): async() {
    // if (init_msg.caller != caller) throw Error.reject("Unauthorized call");
    if (isInitialized) throw Error.reject("Canister has been initialized");

    assetInfo := ?assetMetadata;
    leftToMint := assetMetadata.volumeProduced;
    isInitialized := true;
  };



  /// add token to collection
  public func mintToken(uid: T.UID, amount: Nat) : async T.TokenInfo {
    if (leftToMint < amount) throw Error.reject("Limit tokens to mint is" # Nat.toText(leftToMint));

    /// update leftToMint amount info
    leftToMint := leftToMint - amount;

    // update user into irecs
    let mintedAmount = switch(irecs.get(uid)) {
      case(null) amount;
      case(?currentAmount) currentAmount + amount;
    };
    irecs.put(uid, mintedAmount);

    {
      tokenId = tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = mintedAmount;
      inMarket = leftToMint; // TODO evaluate what value use
    }
  };


  public func burnToken(uid: T.UID, amount: Nat): async T.TokenInfo {
    let burnedAmount: Nat = switch(irecs.get(uid)) {
      case(null) throw Error.reject(userNotFound);
      case(?currentAmount) {
        if (currentAmount < amount) throw Error.reject("Limit tokens to burn is" # Nat.toText(currentAmount));

        currentAmount - amount
      };
    };

    irecs.put(uid, burnedAmount);

    {
      tokenId = tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = burnedAmount;
      inMarket = leftToMint; // TODO evaluate what value use
    }
  };


  public query func getUserMinted(uid: T.UID): async Nat {
    switch(irecs.get(uid)) {
      case(null) throw Error.reject(userNotFound);
      case(?irecMinted) irecMinted;
    };
  };



  public query func getAssetInfo(): async T.AssetInfo {
    switch(assetInfo) {
      case(null) { throw Error.reject("Asset metadata have not generated") };
      case(?value) return value;
    };
  };

  public query func getRemainingAmount(): async Nat { leftToMint };
  
  public query func getTokenId(): async T.TokenId { tokenId };

  public query func getCanisterId(): async T.CanisterId { Principal.fromActor(this) };
}
