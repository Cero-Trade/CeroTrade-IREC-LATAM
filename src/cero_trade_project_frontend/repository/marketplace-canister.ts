export class MarketplaceCanister {
  marketplace: any
  constructor({ marketplace }) {
    this.marketplace = marketplace
  }

  async init(): Promise<void> {
    console.log("here", this.marketplace);
  }
}