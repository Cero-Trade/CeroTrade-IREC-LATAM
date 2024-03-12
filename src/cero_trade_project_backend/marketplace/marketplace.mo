import MarketplaceTypes = "./marketplace_types";

actor Marketplace {
    public func echoListing() : async MarketplaceTypes.Listing {
        return MarketplaceTypes.exampleListing();
    }
}
