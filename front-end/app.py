import uuid
import chainlit as cl
from agents import create_tech_agent, create_travel_agent, use_finance_agent
from multi_agent_orchestrator.orchestrator import MultiAgentOrchestrator, OrchestratorConfig
from multi_agent_orchestrator.classifiers import BedrockClassifier, BedrockClassifierOptions
from multi_agent_orchestrator.types import ConversationMessage
from multi_agent_orchestrator.agents import AgentResponse


# Initialize the orchestrator
custom_bedrock_classifier = BedrockClassifier(BedrockClassifierOptions(
    model_id='anthropic.claude-3-haiku-20240307-v1:0',
    inference_config={
        'maxTokens': 500,
        'temperature': 0.7,
        'topP': 0.9
    }
))

orchestrator = MultiAgentOrchestrator(options=OrchestratorConfig(
        LOG_AGENT_CHAT=True,
        LOG_CLASSIFIER_CHAT=True,
        LOG_CLASSIFIER_RAW_OUTPUT=True,
        LOG_CLASSIFIER_OUTPUT=True,
        LOG_EXECUTION_TIMES=True,
        MAX_RETRIES=3,
        USE_DEFAULT_AGENT_IF_NONE_IDENTIFIED=False,
        MAX_MESSAGE_PAIRS_PER_AGENT=10
    ),
    classifier=custom_bedrock_classifier
)

# Add agents to the orchestrator
orchestrator.add_agent(create_tech_agent())
orchestrator.add_agent(create_travel_agent())
orchestrator.add_agent(use_finance_agent())

@cl.on_chat_start
async def start():
    cl.user_session.set("user_id", str(uuid.uuid4()))
    cl.user_session.set("session_id", str(uuid.uuid4()))
    cl.user_session.set("chat_history", [])



@cl.on_message
async def main(message: cl.Message):
    user_id = cl.user_session.get("user_id")
    session_id = cl.user_session.get("session_id")

    msg = cl.Message(content="")

    await msg.send()  # Send the message immediately to start streaming
    cl.user_session.set("current_msg", msg)

    response = await orchestrator.route_request(message.content, user_id, session_id, {})

    # Handle non-streaming responses
    if isinstance(response, AgentResponse) and response.streaming is False:
        # Handle regular response
        if isinstance(response.output, str):
            await msg.stream_token(response.output)
        elif isinstance(response.output, ConversationMessage):
                await msg.stream_token(response.output.content[0].get('text'))
    await msg.update()


if __name__ == "__main__":
    cl.run()