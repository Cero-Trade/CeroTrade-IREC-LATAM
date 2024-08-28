import HM = "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
// import Source "mo:uuid/async/SourceV4";
import Error "mo:base/Error";


// types
import T "../types";

shared({ caller = bucketIndexCaller }) actor class Bucket() {
  var bucket: HM.HashMap<T.BucketId, T.ArrayFile> = HM.HashMap(16, Text.equal, Text.hash);
  stable var bucketEntries : [(T.BucketId, T.ArrayFile)] = [];


  /// funcs to persistent collection state
  system func preupgrade() { bucketEntries := Iter.toArray(bucket.entries()) };
  system func postupgrade() {
    bucket := HM.fromIter<T.BucketId, T.ArrayFile>(bucketEntries.vals(), 16, Text.equal, Text.hash);
    bucketEntries := [];
  };

  private func _callValidation(caller: Principal) { assert bucketIndexCaller == caller };

  /// get size of bucket collection
  public query func length(): async Nat { bucket.size() };

  // get file on Cero Trade bucket
  public shared({ caller }) func getFile(bucketId: T.BucketId): async T.ArrayFile {
    _callValidation(caller);

    switch(bucket.get(bucketId)) {
      case(null) throw Error.reject("File not found");
      case(?value) value;
    };
  };

  // get files on Cero Trade bucket
  public shared({ caller }) func getFiles(bucketIds: [T.BucketId]): async [T.ArrayFile] {
    _callValidation(caller);

    let files = Buffer.Buffer<T.ArrayFile>(50);

    for(bucketId in bucketIds.vals()) {
      switch(bucket.get(bucketId)) {
        case(null) {};
        case(?value) files.add(value);
      };
    };

    Buffer.toArray<T.ArrayFile>(files);
  };

  /// add file to Cero Trade bucket
  public shared({ caller }) func addFile(bucketId: T.BucketId, file: T.ArrayFile): async () {
    _callValidation(caller);

    if (bucket.get(bucketId) != null) throw Error.reject("BucketId already exists");

    bucket.put(bucketId, file);
  };

  /// add file to Cero Trade bucket
  public shared({ caller }) func addFiles(files: [(T.BucketId, T.ArrayFile)]): async () {
    _callValidation(caller);

    for((bucketId, file) in files.vals()) {
      if (bucket.get(bucketId) == null) bucket.put(bucketId, file);
    };
  };

  /// clear file from Cero Trade bucket
  public shared({ caller }) func clearFile(bucketId: T.BucketId): async() {
    _callValidation(caller);

    let _ = bucket.remove(bucketId);
  };

  /// clear files from Cero Trade bucket
  public shared({ caller }) func clearFiles(bucketIds: [T.BucketId]): async() {
    _callValidation(caller);

    for(bucketId in bucketIds.vals()) {
      let _ = bucket.remove(bucketId);
    };
  };
}
