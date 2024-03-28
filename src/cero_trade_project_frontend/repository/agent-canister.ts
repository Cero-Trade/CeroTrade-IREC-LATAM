import { useAgentCanister as agent } from "@/services/icp-provider";

export class AgentCanister {
  static async register(data: {
    id: string,
    name: string,
    country: string,
    city: string,
    address: string,
    email: string,
  }): Promise<void> {
    console.log("here", data, agent());
  }
}