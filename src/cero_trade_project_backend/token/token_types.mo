module {
    public type Token = {
        id: Nat64;
        name: Text;
        supply: Nat64;
    };

    public func exampleToken() : Token {
        return {
            id = 1;
            name = "Example Token";
            supply = 1000;
        };
    }
}
