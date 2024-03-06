import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

module {

    // Define a structure for information about individual tokens
    public type TokenSaleInfo = {
        tokenId: Text;        // A unique identifier for the token
        totalAmount: Nat;     // The total amount of tokens the user owns
        amountForSale: Nat;   // The amount of tokens the user has posted for sale
    };

    // Define a type for a list of tokens with sale information
    public type TokenList = [TokenSaleInfo];

    // Define a type for a list of tokens that were redeemed by the user
    public type RedemptionList = [TokenSaleInfo];

    // Define a structure for a user's information
    public type UserInfo = {
        vaultToken: Text;     // The token corresponding to the user in the centralized token vault
        principal: Principal; // The user's Internet Identity principal
        tokens: TokenList;    // A list of tokens owned by the user
    };

};
