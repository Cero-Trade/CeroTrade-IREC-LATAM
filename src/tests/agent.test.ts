import { expect, test } from "vitest";
import { Actor, CanisterStatus, HttpAgent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { agentCanister, agentActor } from "./test-actor";
import { identity } from "./test-identity";


test("Should contain a candid interface", async () => {
  const agent = Actor.agentOf(await agentActor) as HttpAgent,
  canisterId = Principal.from(agentCanister),

  canisterStatus = await CanisterStatus.request({
    canisterId,
    agent,
    paths: ["time", "controllers"],
  });

  expect(canisterStatus.get("time")).toBeTruthy();
  expect(Array.isArray(canisterStatus.get("controllers"))).toBeTruthy();
});


test("the identity should be the same", async () => {
  const principal = (await identity).getPrincipal();

  expect(principal.toString()).toMatchInlineSnapshot(
    '"wnkwv-wdqb5-7wlzr-azfpw-5e5n5-dyxrf-uug7x-qxb55-mkmpa-5jqik-tqe"'
  );
});