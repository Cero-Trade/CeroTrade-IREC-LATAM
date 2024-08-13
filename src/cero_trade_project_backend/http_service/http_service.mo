import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Source "mo:uuid/async/SourceV4";
import UUID "mo:uuid/UUID";

// canisters
import UserIndex "canister:user_index";

// types
import T "../types";
import ENV "../env";
import HTTP "./http_service_interface";

//Actor
actor HttpService {
  private func _callValidation(caller: Principal) {
    let authorizedCanisters = [
      ENV.CANISTER_ID_AGENT,
      ENV.CANISTER_ID_USER_INDEX,
      ENV.CANISTER_ID_TOKEN_INDEX,
      ENV.CANISTER_ID_TRANSACTION_INDEX,
      ENV.CANISTER_ID_NOTIFICATION_INDEX,
      ENV.CANISTER_ID_BUCKET_INDEX,
    ];

    assert Array.find<Text>(authorizedCanisters, func x = Principal.fromText(x) == caller) != null;
  };

  // Generate idempotency Key
  private func generateUUID() : async Text {
    let g = Source.Source();
    UUID.toText(await g.new());
  };

  // get url host
  private func getHost(url: Text, port: ?Text): Text {
    let urlParts = Text.split(url, #char '/');
    let urlPartsList = Iter.toArray(urlParts);

    let host: Text = urlPartsList[2];

    let hostingPort = switch(port) {
      case(null) ":443";
      case(?value) value;
    };

    host # hostingPort
  };

  private func _extractHost(url: Text): Text {
    let partsIter = Text.split(url, #char '/');
    let parts = Iter.toArray(partsIter);

    if (Array.size(parts) < 3) {
      return "Error: invalid URL";
    } else {
      return parts[2];
    };
  };

  // CREATE TRANSFORM FUNCTION
  public query func transform(raw : HTTP.TransformArgs) : async HTTP.CanisterHttpResponsePayload {
    let transformed : HTTP.CanisterHttpResponsePayload = {
      status = raw.response.status;
      body = raw.response.body;
      headers = [
        {
          name = "Content-Security-Policy";
          value = "default-src 'self'";
        },
        { name = "Referrer-Policy"; value = "strict-origin" },
        { name = "Permissions-Policy"; value = "geolocation=(self)" },
        {
          name = "Strict-Transport-Security";
          value = "max-age=63072000";
        },
        { name = "X-Frame-Options"; value = "DENY" },
        { name = "X-Content-Type-Options"; value = "nosniff" },
        { name = "Access-Control-Allow-Origin"; value = HTTP.apiUrl }
      ];
    };
    transformed;
  };

  private func _generateHeaders({ url: Text; port: ?Text; uid: ?T.UID; headers: [HTTP.HttpHeader] }) : async [HTTP.HttpHeader] {
    // Idempotency keys should be unique so create a function that generates them.
    let idempotency_key: Text = await generateUUID();

    // Prepare headers for the system http_request call
    let default_headers  = Buffer.fromArray<HTTP.HttpHeader>([
      { name = "Host"; value = getHost(url, port) },
      { name = "User-Agent"; value = HTTP.headerName },
      { name = "Content-Type"; value = "application/json" },
      { name= "Idempotency-Key"; value = idempotency_key }
    ]);

    // used to fetch token from user and return token auth header
    switch(uid) {
      case(null) {};
      case(?value) {
        let token = await UserIndex.getUserToken(value);
        default_headers.add({ name = "token"; value = token; });
      };
    };

    Array.flatten<HTTP.HttpHeader>([
      Buffer.toArray<HTTP.HttpHeader>(default_headers),
      headers
    ]);
  };

  private func _sendRequest<system>(request: HTTP.HttpRequestArgs) : async Text {
    // DECLARE MANAGEMENT CANISTER
    let ic : HTTP.IC = actor ("aaaaa-aa");

    // ADD CYCLES TO PAY FOR HTTP REQUEST

    //The IC specification spec says, "Cycles to pay for the call must be explicitly transferred with the call"
    //The management canister will make the HTTP request so it needs cycles
    //See: https://internetcomputer.org/docs/current/motoko/main/cycles

    //The way Cycles.add() works is that it adds those cycles to the next asynchronous call
    //"Function add(amount) indicates the additional amount of cycles to be transferred in the next remote call"
    //See: https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-http_request
    Cycles.add<system>(T.cycles);

    // MAKE HTTPS REQUEST AND WAIT FOR RESPONSE
    //Since the cycles were added above, you can just call the management canister with HTTPS outcalls below
    let http_response : HTTP.HttpResponsePayload = await ic.http_request(request);

    // DECODE THE RESPONSE

    //As per the type declarations in `src/http_service_types.mo`, the BODY in the HTTP response
    //comes back as [Nat8s] (e.g. [2, 5, 12, 11, 23]). Type signature:

    //public type HttpResponsePayload = {
    //     status : Nat;
    //     headers : [HttpHeader];
    //     body : [Nat8];
    // };

    //You need to decode that [Nat8] array that is the body into readable text.
    //To do this, you:
    //  1. Convert the [Nat8] into a Blob
    //  2. Use Blob.decodeUtf8() method to convert the Blob to a ?Text optional
    //  3. You use a switch to explicitly call out both cases of decoding the Blob into ?Text
    let response_body: Blob = Blob.fromArray(http_response.body);
    let decoded_text: Text = switch (Text.decodeUtf8(response_body)) {
      case (null) "No value returned";
      case (?y) y;
    };

    // CHECK THE STATUS OF THE RESPONSE
    // If the status is not in the range 200-299, it indicates an error.
    if (http_response.status < 200 or http_response.status > 299) {
      throw HTTP.httpError({ status = http_response.status; body = decoded_text });
    };

    decoded_text
  };


  public shared({ caller }) func get({ url: Text; port: ?Text; uid: ?T.UID; headers: [HTTP.HttpHeader]; }) : async Text {
    _callValidation(caller);

    // SETUP ARGUMENTS FOR HTTP GET request

    // Transform context
    let transform_context : HTTP.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    // The HTTP request
    let http_request : HTTP.HttpRequestArgs = {
      url;
      max_response_bytes = null; //optional for request
      headers = await _generateHeaders({ url; port; uid; headers });
      body = null;
      method = #get;
      transform = ?transform_context;
    };

    await _sendRequest(http_request)
  };


  public shared({ caller }) func post({ url: Text; port: ?Text; uid: ?T.UID; headers: [HTTP.HttpHeader]; bodyJson: Text }) : async Text {
    _callValidation(caller);

    // SETUP ARGUMENTS FOR HTTP POST request

    // Transform context
    let transform_context : HTTP.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    let request_body_as_Blob: Blob = Text.encodeUtf8(bodyJson);
    let request_body_as_nat8: [Nat8] = Blob.toArray(request_body_as_Blob);

    // The HTTP request
    let http_request : HTTP.HttpRequestArgs = {
      url;
      // TODO under testing, this could be null or Nat64.fromNat(1024 * 1024)
      max_response_bytes = ?Nat64.fromNat(1024 * 1024); //optional for request
      headers = await _generateHeaders({ url; port; uid; headers });
      body = ?request_body_as_nat8; //provide body for POST request
      method = #post;
      transform = ?transform_context;
    };

    await _sendRequest(http_request)
  };
};
