module {
    public type UserIndex = {
        userId: Nat64;
        index: Nat;
    };

    public func exampleUserIndex() : UserIndex {
        return {
            userId = 1;
            index = 0;
        };
    }
}
