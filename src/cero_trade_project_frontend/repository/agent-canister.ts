import { useAgentCanister as agent } from "@/services/icp-provider";

export class AgentCanister {
  static async register(): Promise<void> {
    console.log("here", agent());
  }
}