export class TokenCanister {
    token: any
    constructor({ token }) {
      this.token = token
    }

    async init(): Promise<void> {
      console.log("here", this.token);
    }
}