data "aws_bedrock_foundation_model" "agent" {
  model_id = var.agent_model_id
}

data "aws_bedrock_foundation_model" "kb" {
  model_id = var.kb_model_id
}

################################################################################
# Bedrock Knowledge Base
################################################################################

resource "awscc_bedrock_knowledge_base" "this" {
  name     = var.kb_name
  role_arn = aws_iam_role.bedrock_kb.arn
  knowledge_base_configuration = {
    vector_knowledge_base_configuration = {
      embedding_model_arn = data.aws_bedrock_foundation_model.kb.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration = {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration = {
      collection_arn    = aws_opensearchserverless_collection.this.arn
      vector_index_name = var.vector_index_name
      field_mapping = {
        vector_field   = var.vector_index_name
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  tags = local.tags
  depends_on = [
    aws_iam_role_policy.bedrock_kb_model,
    aws_iam_role_policy.bedrock_kb_s3,
    aws_iam_role_policy.bedrock_kb_oss,
    opensearch_index.this,
    time_sleep.aws_iam_role_policy_bedrock_kb_oss
  ]
}

resource "awscc_bedrock_data_source" "this" {
  knowledge_base_id = awscc_bedrock_knowledge_base.this.id
  name              = "${var.kb_name}DataSource"
  description       = "${var.kb_name} datasource"
  data_source_configuration = {
    type = "S3"
    s3_configuration = {
      bucket_arn = aws_s3_bucket.bedrock_kb.arn
    }
  }
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
resource "awscc_bedrock_agent" "this" {
  agent_name              = var.agent_name
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  description             = var.agent_description
  foundation_model        = data.aws_bedrock_foundation_model.agent.model_id
  instruction             = file("${path.module}/prompt-templates/agent_instructions.txt")

  idle_session_ttl_in_seconds = 600
  auto_prepare                = true

  knowledge_bases = [{
    description          = var.agent_kb_association_description
    knowledge_base_id    = awscc_bedrock_knowledge_base.this.id
    knowledge_base_state = "ENABLED"
  }]

  action_groups = [{
    action_group_name                    = var.agent_action_group
    description                          = var.agent_action_group_description
    skip_resource_in_use_check_on_delete = true
    action_group_executor = {
      lambda = aws_lambda_function.bedrock_action_group.arn
    }
    api_schema = {
      payload = file("${path.module}/lambda/knowledge-base/schema.yaml")
    }

  }]

  prompt_override_configuration = {
    prompt_configurations = [
      {
        base_prompt_template = file("${path.module}/prompt-templates/orchestration.txt")
        inference_configuration = {
          max_length = 2048
          stop_sequences = [
            "$invoke$",
            "$answer$",
            "$error$"
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
    aws_iam_role_policy.bedrock_agent_kb,
    aws_iam_role_policy.bedrock_agent_model,
  ]
}

resource "awscc_bedrock_agent_alias" "this" {
  agent_alias_name = var.agent_name
  description      = var.agent_name
  agent_id         = awscc_bedrock_agent.this.id

  tags = local.tags
}