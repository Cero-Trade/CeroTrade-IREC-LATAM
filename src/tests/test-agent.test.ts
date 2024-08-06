import { expect, test } from "vitest";
import { Actor, CanisterStatus, HttpAgent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { agentCanisterId, agentActor, identity } from "./test-icp-provider";

test("should handle a basic greeting", async () => {
  const result1 = (await agentActor).login();
  // expect(result1).toBe("Hello, test!");
});

test("Should contain a candid interface", async () => {
  const agent = Actor.agentOf(await agentActor) as HttpAgent,
  canisterId = Principal.from(agentCanisterId);

  const canisterStatus = await CanisterStatus.request({
    canisterId,
    agent,
    paths: ["time", "controllers", "candid"],
  });

  expect(canisterStatus.get("time")).toBeTruthy();
  expect(Array.isArray(canisterStatus.get("controllers"))).toBeTruthy();
  // expect(canisterStatus.get("candid")).toMatchInlineSnapshot(`
  //   "service : {
  //     greet: (text) -> (text) query;
  //   }
  //   "
  // `);
});

test("the identity should be the same", async () => {
  const principal = (await identity).getPrincipal();
  expect(principal.toString()).toMatchInlineSnapshot('"wnkwv-wdqb5-7wlzr-azfpw-5e5n5-dyxrf-uug7x-qxb55-mkmpa-5jqik-tqe"');
});