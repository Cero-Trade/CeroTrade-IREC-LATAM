import { Tokens } from "@/models/transaction-model";
import { getLedgerCanister as ledger } from "@/services/icp-provider";
import { Account, ApproveResult, Icrc1BlockIndex } from "src/declarations/nns-ledger/nns-ledger.did";
import { AgentCanister } from "./agent-canister";

export class LedgerCanister {
  static async approveICP({ spender, amount }: { spender: Account, amount: Tokens }): Promise<Icrc1BlockIndex> {
    try {
      const result = await ledger().icrc2_approve({
        fee: [],
        memo: [],
        from_subaccount: [],
        created_at_time: [],
        amount: amount.e8s,
        expected_allowance: [],
        expires_at: [],
        spender: {
          owner: spender.owner,
          subaccount: spender.subaccount?.length ? [spender.subaccount] : [],
        },
      }) as ApproveResult;
      if (result['Err']) throw result['Err']

      return result['Ok'];
    } catch (error) {
      console.error(error);
      throw error.toString()
    }
  }


  static async approveICPFromToken({ tokenId, amount }: {
    tokenId: string,
    amount: Tokens
  }): Promise<Icrc1BlockIndex> {
    try {
      const tokenCanister = await AgentCanister.getTokenCanister(tokenId),
      result = await ledger().icrc2_approve({
        fee: [10_000],
        memo: [],
        from_subaccount: [],
        created_at_time: [],
        amount: amount.e8s,
        expected_allowance: [],
        expires_at: [],
        spender: {
          owner: tokenCanister,
          subaccount: [],
        },
      }) as ApproveResult;
      if (result['Err']) throw result['Err']

      return result['Ok'];
    } catch (error) {
      const newError = Object.entries(error)[0],
      message = Object.entries(newError[1])[0],
      errorMessage = `${newError[0]}: ${message[0]} - ${message[1]}`

      console.error(errorMessage);
      throw errorMessage
    }
  }
}