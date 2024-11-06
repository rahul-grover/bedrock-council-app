################################################################################
# Bedrock Agent
################################################################################

# awscc_bedrock_agent creation unsuccessful with only required inputs 
# https://github.com/hashicorp/terraform-provider-awscc/issues/1572
# aws_bedrockagent_agent prompt override block causes missing required field
# https://github.com/hashicorp/terraform-provider-aws/issues/37903
# aws_bedrockagent_agent resource fails to create due to inconsistent result after apply
# https://github.com/hashicorp/terraform-provider-aws/issues/37168
resource "awscc_bedrock_agent" "agent_test_data" {
  agent_name              = var.test_data_agent_name
  agent_resource_role_arn = aws_iam_role.test_data_bedrock_agent.arn
  description             = var.test_data_agent_description
  foundation_model        = data.aws_bedrock_foundation_model.agent_test_data.model_id
  instruction             = file("agent_instructions_test_data.txt")

  idle_session_ttl_in_seconds = 600
  auto_prepare                = true

  prompt_override_configuration = {
    prompt_configurations = [
      {
        base_prompt_template = file("orchestration_test_data.json")
        inference_configuration = {
          max_length = 2048
          stop_sequences = [
            "</invoke>",
            "</answer>",
            "</error>"
          ]
          temperature = 0
          top_k       = 250
          top_p       = 1
        }
        parser_mode          = "DEFAULT"
        prompt_creation_mode = "OVERRIDDEN"
        prompt_state         = "ENABLED"
        prompt_type          = "ORCHESTRATION"
      }
    ]
  }

  tags = local.tags
  depends_on = [
    aws_iam_role_policy.test_data_bedrock_agent_model,
  ]
}

resource "awscc_bedrock_agent_alias" "agent_alias_test_data" {
  agent_alias_name = var.test_data_agent_name
  description      = var.test_data_agent_description
  agent_id         = awscc_bedrock_agent.agent_test_data.id
  depends_on = [ awscc_bedrock_agent.agent_test_data ]
  tags = local.tags
}
