output "tfc_workspace_name" {
  description = "TFC Workspace Name"
  value       = var.TFC_WORKSPACE_NAME
}

################################################################################
# OpenSearch
################################################################################

output "opensearch_serverless_collection_endpoint" {
  description = "Opensearch serverless collection endpoint"
  value       = aws_opensearchserverless_collection.this.collection_endpoint
}

output "opensearch_serverless_collection_arn" {
  description = "Opensearch serverless collection arn"
  value       = aws_opensearchserverless_collection.this.arn
}

output "opensearch_serverless_collection_id" {
  description = "Opensearch serverless collection id"
  value       = aws_opensearchserverless_collection.this.id
}