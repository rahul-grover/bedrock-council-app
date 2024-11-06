################################################################################
# Bedrock Agent IAM Role
################################################################################

resource "aws_iam_role" "test_data_bedrock_agent" {
  name = "AmazonBedrockExecutionRoleForAgents_${var.test_data_agent_name}"
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

################################################################################
# Bedrock Agent IAM Policy
################################################################################

resource "aws_iam_role_policy" "test_data_bedrock_agent_model" {
  name = "AmazonBedrockAgentBedrockFoundationModelPolicy_${var.test_data_agent_name}"
  role = aws_iam_role.test_data_bedrock_agent.name
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