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
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
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
#   description             = var.agent_desc
#   foundation_model        = data.aws_bedrock_foundation_model.agent.model_id
#   instruction             = file("${path.module}/prompt_templates/instruction.txt")
#   depends_on = [
#     aws_iam_role_policy.bedrock_agent_kb,
#     aws_iam_role_policy.bedrock_agent_model
#   ]
# }

# resource "aws_bedrockagent_agent_action_group" "this" {
#   action_group_name          = var.action_group_name
#   agent_id                   = aws_bedrockagent_agent.this.id
#   agent_version              = "DRAFT"
#   description                = var.action_group_desc
#   skip_resource_in_use_check = true
#   action_group_executor {
#     lambda = aws_lambda_function.bedrock_action_group.arn
#   }
#   api_schema {
#     payload = file("${path.module}/lambda/knowledge-base/schema.yaml")
#   }
# }

# resource "aws_bedrockagent_agent_knowledge_base_association" "forex_kb" {
#   agent_id             = aws_bedrockagent_agent.forex_asst.id
#   description          = file("${path.module}/prompt_templates/kb_instruction.txt")
#   knowledge_base_id    = aws_bedrockagent_knowledge_base.forex_kb.id
#   knowledge_base_state = "ENABLED"
# }

