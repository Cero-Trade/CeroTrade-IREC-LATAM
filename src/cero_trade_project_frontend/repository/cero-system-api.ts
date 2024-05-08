import { useAgentCanister as agent, getErrorMessage } from "@/services/icp-provider";
import { AuthClientApi } from "./auth-client-api";

export class CeroSystemApi {
  static async mintToken({ user, tokenId, tokenAmount }: {
    user: string,
    tokenId: string,
    tokenAmount: number,
  }): Promise<void> {
    try {
      await agent().mintToken(user, tokenId, tokenAmount)
    } catch (error) {
      console.error(error);
      throw getErrorMessage(error)
    }
  }
}
