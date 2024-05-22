import { Principal } from "@dfinity/principal";

export class AgentCanister {
  // TODO test this function
  static async approveICP(to: Principal, amount: number): Promise<any> {
    try {
      // const result = await getLedgerCanister().send_dfx({
      //   to,
      //   amount: { e8s: BigInt(amount) },
      //   fee: { e8s: BigInt(0) },
      //   memo: BigInt(Date.now()),
      //   from_subaccount: [],
      //   created_at_time: [],
      // });
      // console.log(result);

      // return result;
    } catch (error) {
      console.error(error);
      throw error.toString()
    }
  }
}