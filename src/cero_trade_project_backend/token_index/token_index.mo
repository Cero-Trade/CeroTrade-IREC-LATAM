import TokenIndexTypes = "./token_index_types";

actor TokenIndex {
    public func echoTokenIndex() : async TokenIndexTypes.TokenIndex {
        return TokenIndexTypes.exampleTokenIndex();
    }
}
