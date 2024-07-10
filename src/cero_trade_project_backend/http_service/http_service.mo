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

// types
import HT "./http_service_types";

//Actor
actor HttpService {

  // Generate idempotency Key
  private func generateUUID() : async Text {
    let g = Source.Source();
    UUID.toText(await g.new());
  };

  // get url host
  private func getHost(url: Text): Text {
    let urlParts = Text.split(url, #char '/');
    let urlPartsList = Iter.toArray(urlParts);

    let host: Text = urlPartsList[2];

    host # HT.port
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
  public query func transform(raw : HT.TransformArgs) : async HT.CanisterHttpResponsePayload {
    let transformed : HT.CanisterHttpResponsePayload = {
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
        { name = "Access-Control-Allow-Origin"; value = HT.apiUrl }
      ];
    };
    transformed;
  };

  private func _generateHeaders({ url: Text; headers: [HT.HttpHeader] }) : async [HT.HttpHeader] {
    //idempotency keys should be unique so create a function that generates them.
    let idempotency_key: Text = await generateUUID();

    // prepare headers for the system http_request call
    let default_headers  = Buffer.fromArray<HT.HttpHeader>([
      { name = "Host"; value = getHost(url) },
      { name = "User-Agent"; value = HT.headerName },
      { name = "Content-Type"; value = "application/json" },
      { name= "Idempotency-Key"; value = idempotency_key }
    ]);

    default_headers.append(Buffer.fromArray<HT.HttpHeader>(headers));
    Buffer.toArray<HT.HttpHeader>(default_headers);
  };

  private func _sendRequest<system>(request: HT.HttpRequestArgs) : async Text {
    // DECLARE MANAGEMENT CANISTER
    let ic : HT.IC = actor ("aaaaa-aa");

    // ADD CYCLES TO PAY FOR HTTP REQUEST

    //The IC specification spec says, "Cycles to pay for the call must be explicitly transferred with the call"
    //The management canister will make the HTTP request so it needs cycles
    //See: https://internetcomputer.org/docs/current/motoko/main/cycles

    //The way Cycles.add() works is that it adds those cycles to the next asynchronous call
    //"Function add(amount) indicates the additional amount of cycles to be transferred in the next remote call"
    //See: https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-http_request
    Cycles.add<system>(20_949_972_000);

    // MAKE HTTPS REQUEST AND WAIT FOR RESPONSE
    //Since the cycles were added above, you can just call the management canister with HTTPS outcalls below
    let http_response : HT.HttpResponsePayload = await ic.http_request(request);

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
      throw HT.httpError({ status = http_response.status; body = decoded_text });
    };

    decoded_text
  };


  public func get(url: Text, { headers: [HT.HttpHeader]; }) : async Text {
    // SETUP ARGUMENTS FOR HTTP GET request

    // Transform context
    let transform_context : HT.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    // The HTTP request
    let http_request : HT.HttpRequestArgs = {
      url;
      max_response_bytes = null; //optional for request
      headers = await _generateHeaders({ url; headers });
      body = null; //optional for request
      method = #get;
      transform = ?transform_context;
    };

    await _sendRequest(http_request)
  };


  public func post(url: Text, { headers: [HT.HttpHeader]; bodyJson: Text }) : async Text {
    // SETUP ARGUMENTS FOR HTTP POST request

    // Transform context
    let transform_context : HT.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    let request_body_as_Blob: Blob = Text.encodeUtf8(bodyJson);
    let request_body_as_nat8: [Nat8] = Blob.toArray(request_body_as_Blob);

    // The HTTP request
    let http_request : HT.HttpRequestArgs = {
      url;
      // TODO under testing, this could be null or Nat64.fromNat(1024 * 1024)
      max_response_bytes = ?Nat64.fromNat(1024 * 1024); //optional for request
      headers = await _generateHeaders({ url; headers });
      body = ?request_body_as_nat8; //provide body for POST request
      method = #post;
      transform = ?transform_context;
    };

    await _sendRequest(http_request)
  };
};
