import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";

export class TokensCanister {
  static async mintToken(tokenId: string, amount: number): Promise<void> {
    try {
      await agent().mintToken(tokenId, amount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }

  static async burnToken(tokenId: string, amount: number): Promise<void> {
    try {
      await agent().burnToken(tokenId, amount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}