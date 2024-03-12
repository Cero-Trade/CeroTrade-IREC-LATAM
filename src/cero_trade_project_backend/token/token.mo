import TokenTypes = "./token_types";

actor Token {
    public func echoToken() : async TokenTypes.Token {
        return TokenTypes.exampleToken();
    }
}
