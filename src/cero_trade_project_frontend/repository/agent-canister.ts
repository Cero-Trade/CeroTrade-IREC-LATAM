export class AgentCanister {
  agent: any
  constructor({ agent }) {
    this.agent = agent
  }

  async init(): Promise<void> {
    console.log("here", this.agent);
  }
}