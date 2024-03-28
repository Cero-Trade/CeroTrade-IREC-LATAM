import { useAgentCanister as agent, getErrorMessage, getErrorStatus } from "@/services/icp-provider";

export class AgentCanister {
  static async register(data: {
    id: string,
    name: string,
    country: string,
    city: string,
    address: string,
    email: string,
  }): Promise<string> {
    try {
      return await agent().register(JSON.stringify(data)) as string
    } catch (error) {
      throw getErrorMessage(error)
    }
  }
}