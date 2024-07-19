data "aws_caller_identity" "current" {
  count = var.create ? 1 : 0
}

data "aws_partition" "this" {}

data "aws_region" "this" {}

data "aws_bedrock_foundation_model" "agent" {
  model_id = var.agent_model_id
}

data "aws_bedrock_foundation_model" "kb" {
  model_id = var.kb_model_id
}

locals {
  tags                  = var.tags
  account_id            = data.aws_caller_identity.this.account_id
  partition             = data.aws_partition.this.partition
  region                = data.aws_region.this.name
  region_name_tokenized = split("-", local.region)
  region_short          = "${substr(local.region_name_tokenized[0], 0, 2)}${substr(local.region_name_tokenized[1], 0, 1)}${local.region_name_tokenized[2]}"
}


resource "aws_iam_role" "bedrock_kb_forex_kb" {
  name = "AmazonBedrockExecutionRoleForKnowledgeBase_${var.kb_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_forex_kb_model" {
  name = "AmazonBedrockFoundationModelPolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_forex_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = data.aws_bedrock_foundation_model.kb.model_arn
      }
    ]
  })
}


resource "aws_opensearchserverless_collection" "forex_kb" {
  name = var.kb_oss_collection_name
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_access_policy.forex_kb
  ]
}

resource "aws_iam_role_policy" "bedrock_kb_forex_kb_oss" {
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_forex_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.forex_kb.arn
      }
    ]
  })
}


resource "opensearch_index" "forex_kb" {
  name                           = "bedrock-knowledge-base-default-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1536,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [aws_opensearchserverless_collection.forex_kb]
}

resource "time_sleep" "aws_iam_role_policy_bedrock_kb_forex_kb_oss" {
  create_duration = "20s"
  depends_on      = [aws_iam_role_policy.bedrock_kb_forex_kb_oss]
}

resource "aws_bedrockagent_knowledge_base" "forex_kb" {
  name     = var.kb_name
  role_arn = aws_iam_role.bedrock_kb_forex_kb.arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.kb.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.forex_kb.arn
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy.bedrock_kb_forex_kb_model,
    opensearch_index.forex_kb,
    time_sleep.aws_iam_role_policy_bedrock_kb_forex_kb_oss
  ]
}

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.forex_kb.id
  name              = "${var.kb_name}DataSource"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.bucket_arn
    }
  }
}

# Agent resource role
resource "aws_iam_role" "bedrock_agent_forex_asst" {
  name = "AmazonBedrockExecutionRoleForAgents_${var.agent_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:agent/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_forex_asst_model" {
  name = "AmazonBedrockAgentBedrockFoundationModelPolicy_${var.agent_name}"
  role = aws_iam_role.bedrock_agent_forex_asst.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = data.aws_bedrock_foundation_model.agent.model_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_forex_asst_kb" {
  name = "AmazonBedrockAgentBedrockKnowledgeBasePolicy_${var.agent_name}"
  role = aws_iam_role.bedrock_agent_forex_asst.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:Retrieve"
        Effect   = "Allow"
        Resource = aws_bedrockagent_knowledge_base.forex_kb.arn
      }
    ]
  })
}


# Action group Lambda execution role
resource "aws_iam_role" "lambda_forex_api" {
  name = "FunctionExecutionRoleForLambda_${var.action_group_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${local.account_id}"
          }
        }
      }
    ]
  })
  managed_policy_arns = [data.aws_iam_policy.lambda_basic_execution.arn]
}


resource "aws_bedrockagent_agent" "forex_asst" {
  agent_name              = var.agent_name
  agent_resource_role_arn = aws_iam_role.bedrock_agent_forex_asst.arn
  description             = var.agent_desc
  foundation_model        = data.aws_bedrock_foundation_model.agent.model_id
  instruction             = file("${path.module}/prompt_templates/instruction.txt")
  depends_on = [
    aws_iam_role_policy.bedrock_agent_forex_asst_kb,
    aws_iam_role_policy.bedrock_agent_forex_asst_model
  ]
}

resource "aws_bedrockagent_agent_action_group" "forex_api" {
  action_group_name          = var.action_group_name
  agent_id                   = aws_bedrockagent_agent.forex_asst.id
  agent_version              = "DRAFT"
  description                = var.action_group_desc
  skip_resource_in_use_check = true
}

resource "aws_bedrockagent_agent_knowledge_base_association" "forex_kb" {
  agent_id             = aws_bedrockagent_agent.forex_asst.id
  description          = file("${path.module}/prompt_templates/kb_instruction.txt")
  knowledge_base_id    = aws_bedrockagent_knowledge_base.forex_kb.id
  knowledge_base_state = "ENABLED"
}
