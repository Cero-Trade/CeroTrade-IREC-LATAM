import Principal "mo:base/Principal";

// types
import T "../types"

module BucketInterface {
  public func canister(cid: Principal): Bucket { actor (Principal.toText(cid)) };

  public type Bucket = actor {
    length: query () -> async Nat;
    getFile: (T.BucketId) -> async T.ArrayFile;
    getFiles: ([T.BucketId]) -> async [T.ArrayFile];
    addFile: (T.BucketId, T.ArrayFile) -> async ();
    addFiles: ([(T.BucketId, T.ArrayFile)]) -> async ();
    clearFiles: ([T.BucketId]) -> async();
    clearFile: (T.BucketId) -> async();
  };
}