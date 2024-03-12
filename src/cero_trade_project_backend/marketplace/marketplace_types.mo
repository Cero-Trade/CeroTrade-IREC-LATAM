module {
    public type Listing = {
        listingId: Nat64;
        tokenId: Nat64;
        seller: Text;
        price: Nat64;
    };

    public func exampleListing() : Listing {
        return {
            listingId = 1;
            tokenId = 1;
            seller = "Seller Name";
            price = 500;
        };
    }
}
