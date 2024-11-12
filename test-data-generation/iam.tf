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
        Resource = data.aws_bedrock_foundation_model.agent_test_data.model_arn
      }
    ]
  })
}

################################################################################
# Bedrock Agent Lambda Parser role
################################################################################
resource "aws_iam_role" "lambda_parser" {
  name = "FunctionExecutionRoleForLambda_test_data_generation_lambda_parser"
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

################################################################################
# Bedrock Lambda IAM Role
################################################################################

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda" {
  name = "FunctionExecutionRoleForLambda_test_data_generation"
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