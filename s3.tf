################################################################################
# Random UUID
################################################################################

resource "random_uuid" "uuid" {}

################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "bedrock_kb" {
  bucket        = "${var.bedrock_kb_s3}-${random_uuid.uuid.result}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.bedrock_kb.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "bedrock_logging" {
  for_each      = var.invocation_logging.enabled ? { instance = 1 } : {}
  bucket        = "${var.invocation_logging.bucket_name}-${random_uuid.uuid.result}"
  force_destroy = true
  tags          = local.tags
  lifecycle {
    ignore_changes = [
      tags["CreatorId"], tags["CreatorName"],
    ]
  }
}

resource "aws_s3_bucket_policy" "bedrock_logging" {
  for_each = var.invocation_logging.enabled ? { instance = 1 } : {}
  bucket   = aws_s3_bucket.bedrock_logging.bucket
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "bedrock.amazonaws.com"
      },
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.bedrock_logging["bucket"].arn}/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:bedrock:us-east-1:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }
  ]
}
EOF
}

################################################################################
# Encryption
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.bedrock_kb.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

################################################################################
# Versioning
################################################################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.bedrock_kb.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.this]
}