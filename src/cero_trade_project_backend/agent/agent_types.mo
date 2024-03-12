module {
    public type Agent = {
        id: Nat64;
        role: Text;
    };

    public func exampleAgent() : Agent {
        return {
            id = 1;
            role = "Example Role";
        };
    }
}
