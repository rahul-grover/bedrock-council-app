from multi_agent_orchestrator.agents import BedrockLLMAgent, BedrockLLMAgentOptions, AgentCallbacks, AmazonBedrockAgent, AmazonBedrockAgentOptions
import asyncio

import chainlit as cl

class ChainlitAgentCallbacks(AgentCallbacks):
    def on_llm_new_token(self, token: str) -> None:
        asyncio.run(cl.user_session.get("current_msg").stream_token(token))

def create_tech_agent():
    return BedrockLLMAgent(BedrockLLMAgentOptions(
        name="Tech Agent",
        streaming=True,
        description="Specializes in technology areas including software development, hardware, AI, cybersecurity, blockchain, cloud computing, emerging tech innovations, and pricing/costs related to technology products and services.",
        model_id="anthropic.claude-3-sonnet-20240229-v1:0",
        callbacks=ChainlitAgentCallbacks()
    ))

def use_council_and_finance_agent(agent_id, alias):
    return AmazonBedrockAgent(AmazonBedrockAgentOptions(
        name="Council and Investment Agent",
        description="Investment analyst and Council expert, researches and provides financial data of any company. Create portfolio of top companies in an industry sector. Provides information about the Federal Open Market",
        agent_id=agent_id,
        agent_alias_id=alias
    ))

def use_travel_agent(agent_id, alias):
    return AmazonBedrockAgent(AmazonBedrockAgentOptions(
        name="Travel Agent",
        description="Experienced Travel Agent sought to create unforgettable journeys for clients. Responsibilities include crafting personalized itineraries, booking flights, accommodations, and activities, and providing expert travel advice. Must have excellent communication skills, destination knowledge, and ability to manage multiple bookings. Proficiency in travel booking systems and a passion for customer service required",
        agent_id=agent_id,
        agent_alias_id=alias
    ))
    