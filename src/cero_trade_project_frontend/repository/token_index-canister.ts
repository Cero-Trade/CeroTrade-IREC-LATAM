export class TokenIndexCanister {
  token_index: any
  constructor({ token_index }) {
    this.token_index = token_index
  }

  async init(): Promise<void> {
    console.log("here", this.token_index);
  }
}