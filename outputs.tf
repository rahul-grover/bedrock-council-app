output "tfc_workspace_name" {
  description = "TFC Workspace Name"
  value       = var.TFC_WORKSPACE_NAME
}

#Opensearch serverless collection output
output "opensearch_serverless_collection_endpoint" {
    description = "Opensearch serverless collection endpoint"
    value = aws_opensearchserverless_collection.kb_os_collection.collection_endpoint
}

output "opensearch_serverless_collection_arn" {
    description = "Opensearch serverless collection arn"
    value = aws_opensearchserverless_collection.kb_os_collection.arn
}

output "opensearch_serverless_collection_id" {
    description = "Opensearch serverless collection id"
    value = aws_opensearchserverless_collection.kb_os_collection.id
}