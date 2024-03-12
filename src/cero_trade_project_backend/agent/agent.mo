import AgentTypes = "./agent_types";

actor Agent {
    public func echoAgent() : async AgentTypes.Agent {
        return AgentTypes.exampleAgent();
    }
}
