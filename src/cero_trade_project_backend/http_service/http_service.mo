import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";

// types
import HT "./http_service_types";

//Actor
actor HttpService {

  private func extractHost(url: Text): Text {
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
      ];
    };
    transformed;
  };


  public func get(url: Text, args: { headers: [HT.HttpHeader]; }) : async Text {
    // SETUP ARGUMENTS FOR HTTP GET request

    // Transform context
    let transform_context : HT.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    // The HTTP request
    let http_request : HT.HttpRequestArgs = {
      url = url;
      max_response_bytes = null; //optional for request
      headers = generateHeaders(url, args.headers);
      body = null; //optional for request
      method = #get;
      transform = ?transform_context;
    };

    await sendRequest(http_request)
  };


  public func post(url: Text, args: { headers: [HT.HttpHeader]; bodyJson: Text }) : async Text {
    // SETUP ARGUMENTS FOR HTTP GET request

    // Transform context
    let transform_context : HT.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    let request_body_as_Blob: Blob = Text.encodeUtf8(args.bodyJson);
    let request_body_as_nat8: [Nat8] = Blob.toArray(request_body_as_Blob);

    // The HTTP request
    let http_request : HT.HttpRequestArgs = {
      url = url;
      max_response_bytes = null; //optional for request
      headers = generateHeaders(url, args.headers);
      body = ?request_body_as_nat8; //provide body for POST request
      method = #post;
      transform = ?transform_context;
    };

    await sendRequest(http_request)
  };

  private func generateHeaders(url: Text, customHeaders: [HT.HttpHeader]) : [HT.HttpHeader] {
    // prepare headers for the system http_request call
    let default_headers  = [
      { name = "Host"; value = extractHost(url) # HT.port },
      { name = "User-Agent"; value = HT.headerName },
    ];

    //<!-- TODO try to implements undeprecated merge array -->
    // let merged_headers = Buffer.fromArray<HT.HttpHeader>(default_headers).append(Buffer.fromArray<HT.HttpHeader>(customHeaders));
    // let request_headers = Buffer.toArray(merged_headers);
    Array.append(default_headers, customHeaders);
  };

  private func sendRequest(request: HT.HttpRequestArgs) : async Text {
    // DECLARE MANAGEMENT CANISTER
    //You need this so you can use it to make the HTTP request
    let ic : HT.IC = actor ("aaaaa-aa");

    // ADD CYCLES TO PAY FOR HTTP REQUEST

    //The IC specification spec says, "Cycles to pay for the call must be explicitly transferred with the call"
    //The management canister will make the HTTP request so it needs cycles
    //See: https://internetcomputer.org/docs/current/motoko/main/cycles

    //The way Cycles.add() works is that it adds those cycles to the next asynchronous call
    //"Function add(amount) indicates the additional amount of cycles to be transferred in the next remote call"
    //See: https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-http_request
    Cycles.add(20_949_972_000);

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
        case (null) { "No value returned" };
        case (?y) { y };
    };

    decoded_text
  }
};
