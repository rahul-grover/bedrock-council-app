output "tfc_workspace_name" {
  description = "TFC Workspace Name"
  value       = var.TFC_WORKSPACE_NAME
}

#Opensearch serverless collection output
output "opensearch_serverless_collection_endpoint" {
    description = "Opensearch serverless collection endpoint"
    value = module.opensearch_collection.endpoint
}

output "opensearch_serverless_collection_arn" {
    description = "Opensearch serverless collection arn"
    value = module.opensearch_collection.arn
}

output "opensearch_serverless_collection_id" {
    description = "Opensearch serverless collection id"
    value = module.opensearch_collection.id
}