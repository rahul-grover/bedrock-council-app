data "aws_bedrock_foundation_model" "agent" {
  model_id = var.agent_model_id
}

data "aws_bedrock_foundation_model" "kb" {
  model_id = var.kb_model_id
}

data "aws_bedrock_foundation_models" "test" {}

output "foundation_models" {
  description = "Foundation models"
  value       = data.aws_bedrock_foundation_models.test
}

################################################################################
# Bedrock Knowledge Base
################################################################################

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = var.kb_name
  role_arn = aws_iam_role.bedrock_kb.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.kb.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.this.arn
      vector_index_name = var.vector_index_name
      field_mapping {
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

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${var.kb_name}DataSource"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.bedrock_kb.arn
    }
  }
}

################################################################################
# Bedrock Agent
################################################################################

# resource "aws_bedrockagent_agent" "this" {
#   agent_name              = var.agent_name
#   agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
#   description             = var.agent_description
#   foundation_model        = data.aws_bedrock_foundation_model.agent.model_id
#   instruction             = file("${path.module}/prompt-templates/agent_instructions.txt")
#   # aws_bedrockagent_agent prompt override block causes missing required field, UpdateAgentInput.PromptOverrideConfiguration.PromptConfiguration
#   # https://github.com/hashicorp/terraform-provider-aws/issues/37903
#   # aws_bedrockagent_agent resource fails to create due to inconsistent result after apply
#   # https://github.com/hashicorp/terraform-provider-aws/issues/37168
#   # awscc_bedrock_agent creation unsuccessful with only required inputs 
#   # https://github.com/hashicorp/terraform-provider-awscc/issues/1572
#   # prompt_override_configuration {
#   #   prompt_configurations = [
#   #     {
#   #       base_prompt_template = file("${path.module}/prompt-templates/orchestration.txt")
#   #       inference_configuration = [
#   #         {
#   #           max_length = 2048
#   #           stop_sequences = [
#   #             "$invoke$",
#   #             "$answer$",
#   #             "$error$"
#   #           ]
#   #           temperature = 0
#   #           top_k       = 250
#   #           top_p       = 1
#   #         }
#   #       ]
#   #       parser_mode          = "DEFAULT"
#   #       prompt_creation_mode = "OVERRIDDEN"
#   #       prompt_state         = "ENABLED"
#   #       prompt_type          = "ORCHESTRATION"
#   #     }
#   #   ]
#   # }

#   tags = local.tags
#   depends_on = [
#     aws_iam_role_policy.bedrock_agent_kb,
#     aws_iam_role_policy.bedrock_agent_model,
#   ]
# }

resource "null_resource" "bedrock_agent" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      sh ./scripts/manage_bedrock_agent.sh create \
        ${var.agent_name} ${local.region} \
        ${aws_iam_role.bedrock_agent.arn} \
        ${data.aws_bedrock_foundation_model.agent.model_id}
    EOT
  }

}

data "external" "agent_id" {
  program = [
    "bash", "${path.module}/scripts/manage_bedrock_agent.sh",
    "get",
    var.agent_name,
    local.region
  ]

  depends_on = [
    null_resource.bedrock_agent
  ]
}

resource "aws_bedrockagent_agent_action_group" "this" {
  action_group_name = var.agent_action_group
  # agent_id                   = aws_bedrockagent_agent.this.id
  agent_id                   = data.external.agent_id.result["agent_id"]
  agent_version              = "DRAFT"
  description                = var.agent_action_group_description
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = aws_lambda_function.bedrock_action_group.arn
  }
  api_schema {
    payload = file("${path.module}/lambda/knowledge-base/schema.yaml")
  }

<<<<<<< HEAD

=======
  depends_on = [null_resource.bedrock_agent]
>>>>>>> ecbc3d95ab8fce973265d40635b5f41299c0a2d2
}

resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  # agent_id             = aws_bedrockagent_agent.this.id
  agent_id             = data.external.agent_id.result["agent_id"]
  description          = var.agent_kb_association_description
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  knowledge_base_state = "ENABLED"

}

# Agent must be prepared after changes are made
resource "null_resource" "agent_preparation" {
  triggers = {
    api_state = sha256(jsonencode(aws_bedrockagent_agent_action_group.this))
    kb_state  = sha256(jsonencode(aws_bedrockagent_knowledge_base.this))
  }
  provisioner "local-exec" {
    # command = "aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.this.id} --region ${local.region}"
    command = <<EOT
      aws bedrock-agent prepare-agent --agent-id ${data.external.agent_id.result["agent_id"]} --region ${local.region}
      sleep 20
    EOT
  }
  depends_on = [
    # aws_bedrockagent_agent.this,
    aws_bedrockagent_agent_action_group.this,
    aws_bedrockagent_knowledge_base.this,
    data.external.agent_id
  ]
}

resource "aws_bedrockagent_agent_alias" "this" {
  # agent_id         = aws_bedrockagent_agent.this.id
  agent_id         = data.external.agent_id.result["agent_id"]
  agent_alias_name = var.agent_name

  depends_on = [
    null_resource.agent_preparation
  ]
}