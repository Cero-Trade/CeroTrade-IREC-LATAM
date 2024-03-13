import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

module {
    public type User = {
        id: Nat64;
        name: Text;
    };

    public func exampleUser() : User {
        return {
            id = 1;
            name = "Example User";
        };
    }
}
