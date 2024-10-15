import uuid
import chainlit as cl
from agents import create_tech_agent, use_travel_agent, use_council_and_finance_agent
from multi_agent_orchestrator.orchestrator import MultiAgentOrchestrator, OrchestratorConfig
from multi_agent_orchestrator.classifiers import BedrockClassifier, BedrockClassifierOptions
from multi_agent_orchestrator.types import ConversationMessage
from multi_agent_orchestrator.agents import AgentResponse

import boto3
from botocore.exceptions import ClientError


# Use this code snippet in your app.
# If you need more information about configurations
# or implementing the sample code, visit the AWS docs:
# https://aws.amazon.com/developer/language/python/



def get_secret():

    secret_name = "Council_App_Bedrock"
    region_name = "ap-southeast-2"

    # Create a Secrets Manager client
    # session = boto3.session.Session()
    client = boto3.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']
    return secret


#Get Secrets
agent_details = eval(get_secret())
council_agent_details = (agent_details["Council_and_Insurance_Agent_ID"], agent_details["Council_and_Insurance_Agent_Alias_ID"])
travel_agent_details = (agent_details["Travel_Agent_ID"], agent_details["Travel_Agent_Alias_ID"])

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
orchestrator.add_agent(use_travel_agent(travel_agent_details[0], travel_agent_details[1]))
orchestrator.add_agent(use_council_and_finance_agent(council_agent_details[0], council_agent_details[1]))

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