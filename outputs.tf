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

################################################################################
# Bedrock Knowledge Base 
################################################################################

output "bedrock_kb_id" {
  description = "Unique identifier of the knowledge base"
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "bedrock_kb_arn" {
  description = "ARN of the knowledge base"
  value       = aws_bedrockagent_knowledge_base.this.id
}

################################################################################
# Bedrock Agent
################################################################################

output "bedrock_agent_arn" {
  description = "ARN of the agent"
  value       = aws_bedrockagent_agent.this.agent_arn
}

output "bedrock_agent_id" {
  description = "Unique identifier of the agent"
  value       = aws_bedrockagent_agent.this.agent_id
}