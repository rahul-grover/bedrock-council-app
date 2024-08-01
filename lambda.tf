################################################################################
# Lambda 
################################################################################

data "archive_file" "knowledge_base_zip" {
  type             = "zip"
  source_file      = "${path.module}/lambda/knowledge-base/lambda_function.py"
  output_path      = "${path.module}/tmp/knowledge-base.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "bedrock_action_group" {
  function_name    = var.agent_action_group
  role             = aws_iam_role.lambda.arn
  description      = "A Lambda function for the action group ${var.agent_action_group}"
  filename         = data.archive_file.knowledge_base_zip.output_path
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.knowledge_base_zip.output_base64sha256
  depends_on       = [aws_iam_role.lambda]
  tags             = local.tags
}

resource "aws_lambda_permission" "bedrock_lambda" {
  action         = "lambda:invokeFunction"
  function_name  = aws_lambda_function.bedrock_action_group.function_name
  principal      = "bedrock.amazonaws.com"
  source_account = local.account_id
  source_arn     = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:agent/*"
}

################################################################################
# Lambda Parser
################################################################################

data "archive_file" "parser_zip" {
  type             = "zip"
  source_file      = "${path.module}/lambda/parser/lambda_function.py"
  output_path      = "${path.module}/tmp/parser.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "parser" {
  function_name    = "${var.agent_name}-parser"
  role             = aws_iam_role.lambda_parser.arn
  description      = "A Lambda function for parsing - ${var.agent_action_group}"
  filename         = data.archive_file.parser_zip.output_path
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.parser_zip.output_base64sha256
  depends_on       = [aws_iam_role.lambda]
  tags             = local.tags
}

resource "aws_lambda_permission" "parser" {
  action         = "lambda:invokeFunction"
  function_name  = aws_lambda_function.parser.function_name
  principal      = "bedrock.amazonaws.com"
  source_account = local.account_id
  source_arn     = "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:agent/*"
}
