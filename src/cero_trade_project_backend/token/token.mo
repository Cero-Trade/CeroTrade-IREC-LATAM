import HM = "mo:base/HashMap";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Iter "mo:base/Iter";

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
  stable var leftToMint: Float = 0;


  // constants
  stable let userNotFound: Text = "User not found";



  var userIrecs: HM.HashMap<T.UID, T.TokenInfo> = HM.HashMap(16, Principal.equal, Principal.hash);
  stable var userIrecsEntries : [(T.UID, T.TokenInfo)] = [];


  /// initialization function
  public func init(assetMetadata: T.AssetInfo): async() {
    // if (init_msg.caller != caller) throw Error.reject("Unauthorized call");
    if (isInitialized) throw Error.reject("Canister has been initialized");

    assetInfo := ?assetMetadata;
    leftToMint := assetMetadata.volumeProduced;
    isInitialized := true;
  };

  /// funcs to persistent collection state
  system func preupgrade() { userIrecsEntries := Iter.toArray(userIrecs.entries()) };
  system func postupgrade() {
    userIrecs := HM.fromIter<T.UID, T.TokenInfo>(userIrecsEntries.vals(), 16, Principal.equal, Principal.hash);
    userIrecsEntries := [];
  };



  /// add token to collection
  public func mintToken(uid: T.UID, amount: Float) : async () {
    if (leftToMint < amount) throw Error.reject("Limit tokens to mint is" # Float.toText(leftToMint));

    /// update leftToMint amount info
    leftToMint := leftToMint - amount;

    // update user into userIrecs
    let mintedAmount: Float = switch(userIrecs.get(uid)) {
      case(null) amount;
      case(?token) {
        let currentAmount = token.totalAmount;
        currentAmount + amount
      };
    };

    userIrecs.put(uid, {
      tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = mintedAmount;
      inMarket = leftToMint; // TODO evaluate what value use
      status = #forSale("for sale")
    });
  };


  public func burnToken(uid: T.UID, amount: Float): async() {
    let burnedAmount: Float = switch(userIrecs.get(uid)) {
      case(null) throw Error.reject(userNotFound);
      case(?token) {
        let currentAmount = token.totalAmount;
        if (currentAmount < amount) throw Error.reject("Limit tokens to burn is" # Float.toText(currentAmount));

        currentAmount - amount
      };
    };

    userIrecs.put(uid, {
      tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = burnedAmount;
      inMarket = leftToMint; // TODO evaluate what value use
      status = #forSale("for sale")
    });
  };


  public func purchaseToken(uid: T.UID, recipent: T.UID, amount: Float): async() {
    // burn tokens to recipent
    let burnedAmount: Float = switch(userIrecs.get(recipent)) {
      case(null) throw Error.reject("Recipent user not found");
      case(?token) {
        let currentAmount = token.totalAmount;
        if (currentAmount < amount) throw Error.reject("Limit tokens to burn is" # Float.toText(currentAmount));

        currentAmount - amount
      };
    };

    userIrecs.put(uid, {
      tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = burnedAmount;
      inMarket = leftToMint; // TODO evaluate what value use
      status = #forSale("for sale")
    });


    // mint tokens to buyer
    let mintedAmount: Float = switch(userIrecs.get(uid)) {
      case(null) amount;
      case(?token) {
        let currentAmount = token.totalAmount;
        currentAmount + amount
      };
    };

    userIrecs.put(uid, {
      tokenId;
      assetInfo = await getAssetInfo();
      totalAmount = mintedAmount;
      inMarket = leftToMint; // TODO evaluate what value use
      status = #forSale("for sale")
    });
  };


  public query func getUserMinted(uid: T.UID): async T.TokenInfo {
    switch(userIrecs.get(uid)) {
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

  public query func getRemainingAmount(): async Float { leftToMint };
  
  public query func getTokenId(): async T.TokenId { tokenId };

  public query func getCanisterId(): async T.CanisterId { Principal.fromActor(this) };
}
