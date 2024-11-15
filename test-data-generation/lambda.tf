################################################################################
# Lambda Parser
################################################################################

data "archive_file" "parser_zip" {
  type             = "zip"
  source_file      = "parser/lambda_pre_processing.py"
  output_path      = "${path.module}/tmp/parser.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "parser" {
  function_name    = "${var.test_data_agent_name}-parser"
  role             = aws_iam_role.lambda_parser.arn
  description      = "A Lambda function for parsing orchestration step response"
  filename         = data.archive_file.parser_zip.output_path
  handler          = "lambda_pre_processing.lambda_handler"
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


################################################################################
# Glue processing Lambda
################################################################################

data "archive_file" "glue_processing_zip" {
  type             = "zip"
  source_file      = "parser/glue_dq.py"
  output_path      = "${path.module}/tmp/glue_processing.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "glue_processing_lambda"  {
  function_name    = "${var.test_data_agent_name}-parser"
  role             = aws_iam_role.lambda_parser.arn
  description      = "A Lambda function for processing a file event and running gluedq job on it"
  filename         = data.archive_file.glue_processing_zip.output_path
  handler          = "glue_processing_lambda.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.glue_processing_zip.output_base64sha256
  depends_on       = [aws_iam_role.lambda]
  tags             = local.tags
  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

# IAM role for Lambda
resource "aws_iam_role" "s3_file_processor_role" {
  name = "s3-file-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for the Lambda role
resource "aws_iam_role_policy" "lambda_policy" {
  name = "s3-file-processor-policy"
  role = aws_iam_role.s3_file_processor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.data_generation_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}