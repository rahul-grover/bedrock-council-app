# Generate s3 bucket 
# Add event bridge notification when the file lands in the bucket

# S3 bucket with versioning and encryption enabled
resource "aws_s3_bucket" "data_generation_bucket" {
  bucket = "data-generation-bucket-${data.aws_caller_identity.current.account_id}"

  # Recommended to prevent accidental deletion of bucket
#   force_destroy = false

  tags = local.tags
}

# Enable versioning
# resource "aws_s3_bucket_versioning" "dg_bucket_version" {
#   bucket = aws_s3_bucket.data_generation_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "dg_bucket_encryption" {
  bucket = aws_s3_bucket.data_generation_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "dg_bucket_blockaccess" {
  bucket = aws_s3_bucket.data_generation_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Optional: Add bucket policy
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.data_generation_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.data_generation_bucket.arn,
          "${aws_s3_bucket.data_generation_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}