# Enable EventBridge notifications for the S3 bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.data_generation_bucket.id
  eventbridge = true
}

# Create EventBridge rule
resource "aws_cloudwatch_event_rule" "s3_file_upload" {
  name        = "s3-file-upload-rule"
  description = "Capture file uploads to S3 bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.data_generation_bucket.id]
      },
      object = {
        key = [{
          prefix = "data/"
        }]
      }
    }
  })
}

# {
#   "source": ["aws.s3"],
#   "detail-type": ["AWS API Call via CloudTrail"],
#   "detail": {
#     "eventName": ["PutObject"],
#     "requestParameters": {
#       "bucketName": ["data-generation-bucket-300428143068"],
#       "key": [{
#         "prefix": "data/"
#       }]
#     }
#   }
# }

# EventBridge target
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.s3_file_upload.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.glue_processing_lambda.arn
}

# Lambda permission to allow EventBridge invocation
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_processing_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_file_upload.arn
}