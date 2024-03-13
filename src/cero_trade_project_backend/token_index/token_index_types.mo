module {
    public type TokenIndex = {
        tokenId: Nat64;
        owner: Text;
        balance: Nat64;
    };

    public func exampleTokenIndex() : TokenIndex {
        return {
            tokenId = 1;
            owner = "Owner Name";
            balance = 100;
        };
    }
}

