#Generate bedrockknowledge base with a s3 bucket
# resource "aws_s3_bucket" "bedrockknowledge" {
#   bucket = "rg-bedrock-knowledgebase"
# }

# resource "aws_s3_bucket_public_access_block" "access_bedrockknowledge" {
#   bucket                  = aws_s3_bucket.bedrockknowledge.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
# resource "aws_s3_bucket_versioning" "bedrockknowledge_versioning" {
#   bucket = aws_s3_bucket.bedrockknowledge.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }


data "aws_bedrock_foundation_models" "test" {}

output "foundation_models" {
  description = "Foundation models"
  value       = data.aws_bedrock_foundation_models.test
}