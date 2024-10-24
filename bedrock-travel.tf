data "aws_bedrock_foundation_model" "agent_travel" {
  model_id = var.agent_model_id_travel
}

################################################################################
# Bedrock Agent
################################################################################

# awscc_bedrock_agent creation unsuccessful with only required inputs 
# https://github.com/hashicorp/terraform-provider-awscc/issues/1572
# aws_bedrockagent_agent prompt override block causes missing required field
# https://github.com/hashicorp/terraform-provider-aws/issues/37903
# aws_bedrockagent_agent resource fails to create due to inconsistent result after apply
# https://github.com/hashicorp/terraform-provider-aws/issues/37168
resource "awscc_bedrock_agent" "agent_travel" {
  agent_name              = var.agent_name_travel
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  description             = var.agent_description
  foundation_model        = data.aws_bedrock_foundation_model.agent_travel.model_id
  instruction             = file("${path.module}/prompt-templates/agent_instructions_travel.txt")

  idle_session_ttl_in_seconds = 600
  auto_prepare                = true

  prompt_override_configuration = {
    override_lambda = aws_lambda_function.parser.arn
    prompt_configurations = [
      {
        base_prompt_template = file("${path.module}/prompt-templates/pre_processing_travel.json")
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
        parser_mode          = "OVERRIDDEN"
        prompt_creation_mode = "OVERRIDDEN"
        prompt_state         = "ENABLED"
        prompt_type          = "PRE_PROCESSING"
      }
    ]
  }

  tags = local.tags
  depends_on = [
    aws_iam_role_policy.bedrock_agent_model,
  ]
}

resource "awscc_bedrock_agent_alias" "agent_travel" {
  agent_alias_name = var.agent_name_travel
  description      = var.agent_name_travel
  agent_id         = awscc_bedrock_agent.agent_travel.id

  tags = local.tags
}
