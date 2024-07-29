#!/bin/bash  

ACTION=$1  
AGENT_NAME=$2  
REGION=$3  
ROLE_ARN=$4  
MODEL=$5
tags=("$@")

tag_args=""
for tag in "${tags[@]}"; do
    key="${tag%%=*}"
    value="${tag#*=}"
    tag_args="$tag_args Key=$key,Value=$value"
done

AGENT_INSTRUCTION=$(cat ./prompt-templates/agent_instructions.txt)  

prompt_template=$(cat "./prompt-templates/orchestration.txt")
escaped_prompt=$(echo "$prompt_template" | awk '{printf "%s\\n", $0}' | sed 's/"/\\"/g')
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

AGENT_ID=$(aws bedrock-agent list-agents --query "agentSummaries[?agentName=='$AGENT_NAME'].agentId" --output text)  

case $ACTION in  
    create)  
        if [ -z "$AGENT_ID" ]; then  
            echo "Agent '$AGENT_NAME' does not exist. Creating a new agent..."  
            AGENT_ID=$(aws bedrock-agent create-agent --agent-name "$AGENT_NAME" --region "$REGION" --instruction "$AGENT_INSTRUCTION" --agent-resource-role-arn "$ROLE_ARN" --foundation-model "$MODEL" --prompt-override-configuration "$prompt_override_json" --query 'agent.agentId' --output text)  
            if [ -z "$AGENT_ID" ]; then  
                echo "Failed to create agent '$AGENT_NAME'."  
                exit 1  
            fi  
            echo "Agent '$AGENT_NAME' created with ID: $AGENT_ID"
        else  
            echo "Updating agent '$AGENT_NAME'..."  
            aws bedrock-agent update-agent --agent-id "$AGENT_ID" --agent-name "$AGENT_NAME" --region "$REGION" --instruction "$AGENT_INSTRUCTION" --agent-resource-role-arn "$ROLE_ARN" --foundation-model "$MODEL" --prompt-override-configuration "$prompt_override_json" || {  
                echo "Failed to update agent '$AGENT_NAME'."  
                exit 1  
            }  
            echo "Agent '$AGENT_NAME' updated successfully."
        fi
        ;;
    get)
        echo "{\"agent_id\": \"$AGENT_ID\"}"
        ;;
esac