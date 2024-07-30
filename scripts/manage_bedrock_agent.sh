#!/bin/bash

# Define functions
create_or_update_agent() {
    local agent_name="$1"
    local region="$2"
    local role_arn="$3"
    local model="$4"
    local agent_id=$(aws bedrock-agent list-agents --query "agentSummaries[?agentName=='$agent_name'].agentId" --output text --region "$region")

    if [ -z "$agent_id" ]; then
        echo "Agent '$agent_name' does not exist. Creating a new agent..."
        agent_id=$(aws bedrock-agent create-agent --agent-name "$agent_name" --region "$region" --instruction "$AGENT_INSTRUCTION" --agent-resource-role-arn "$role_arn" --foundation-model "$model" --prompt-override-configuration "$prompt_override_json" --query 'agent.agentId' --output text)
        if [ -z "$agent_id" ]; then
            echo "Failed to create agent '$agent_name'."
            return 1
        fi
        echo "Agent '$agent_name' created with ID: $agent_id"
    else
        echo "Updating agent '$agent_name'..."
        aws bedrock-agent update-agent --agent-id "$agent_id" --agent-name "$agent_name" --region "$region" --instruction "$AGENT_INSTRUCTION" --agent-resource-role-arn "$role_arn" --foundation-model "$model" --prompt-override-configuration "$prompt_override_json" || {
            echo "Failed to update agent '$agent_name'."
            return 1
        }
        echo "Agent '$agent_name' updated successfully."
    fi
}

prepare_agent() {
    local agent_id="$1"
    local region="$2"
    local agent_status=$(aws bedrock-agent get-agent --agent-id "$agent_id" --region "$region" --query 'agent.agentStatus' --output text 2>/dev/null)

    if [ "$agent_status" = "PREPARED" ]; then
        return 0
    fi

    aws bedrock-agent prepare-agent --agent-id "$agent_id" --region "$region"

    # Wait for the agent to be prepared
    while true; do
        agent_status=$(aws bedrock-agent get-agent --agent-id "$agent_id" --region "$region" --query 'agent.agentStatus' --output text)
        if [ "$agent_status" = "PREPARED" ]; then
            break
        fi
        echo "Agent is not ready yet. Waiting for 10 seconds..."
        echo "Agent status: $agent_status"
        sleep 10
    done
}

# Read input parameters
ACTION=$1
AGENT_NAME=$2
REGION=$3
ROLE_ARN=$4
MODEL=$5

# Read agent instructions and prompt template
AGENT_INSTRUCTION=$(cat ./prompt-templates/agent_instructions.txt)
prompt_template=$(cat "./prompt-templates/orchestration.txt")

# Escape prompt template for JSON
escaped_prompt=$(echo "$prompt_template" | awk '{printf "%s\\n", $0}' | sed 's/"/\\"/g')

# Create prompt override JSON
prompt_override_json=$(cat <<EOT
{
    "promptConfigurations": [
        {
        "promptType": "ORCHESTRATION",
        "promptCreationMode": "OVERRIDDEN",
        "basePromptTemplate": "$escaped_prompt",
        "inferenceConfiguration": {
            "temperature": 0.7,
            "topP": 0.9,
            "topK": 250,
            "maximumLength": 2048
        },
        "parserMode": "DEFAULT",
        "promptState": "ENABLED"
        }
    ]
}
EOT
)

# Execute based on the action
case $ACTION in
    create)
        create_or_update_agent "$AGENT_NAME" "$REGION" "$ROLE_ARN" "$MODEL"
        ;;
    get)
        agent_id=$(aws bedrock-agent list-agents --query "agentSummaries[?agentName=='$AGENT_NAME'].agentId" --output text --region "$REGION")
        echo "{\"agent_id\": \"$agent_id\"}"
        ;;
    prepare)
        agent_id=$(aws bedrock-agent list-agents --query "agentSummaries[?agentName=='$AGENT_NAME'].agentId" --output text --region "$REGION")
        prepare_agent "$agent_id" "$REGION"
        ;;
    *)
        echo "Invalid action: $ACTION"
        exit 1
        ;;
esac