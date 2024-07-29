################################################################################
# Common
################################################################################

variable "TFC_WORKSPACE_NAME" {
  description = "Workspace of the infrastructure"
  type        = string
}

variable "pipeline_iam_role" {
  description = "The IAM role name"
  type        = string
  default     = "rg-bedrock-admin-role"
}

################################################################################
# OpenSearch
################################################################################

variable "collection_name" {
  type        = string
  description = "Name of the Collection"
  default     = "e2e-rag-collection"
}

variable "vector_index_name" {
  type        = string
  description = "Index name to be created in vector store"
  default     = "bedrock-knowledge-base-default-index"
}


################################################################################
# Bedrock Knowledge Base
################################################################################

variable "bedrock_kb_s3" {
  type        = string
  description = "S3 bucket name for Bedrock KB"
  default     = "e2e-rag-kb"
}

variable "kb_name" {
  description = "The knowledge base name."
  type        = string
  default     = "e2e-rag-kb"
}

variable "kb_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "cohere.embed-english-v3"
}

################################################################################
# Bedrock Agent
################################################################################

variable "agent_model_id" {
  description = "The ID of the foundational model used by the agent."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "agent_name" {
  description = "The agent name."
  type        = string
  default     = "e2e-rag-agent"
}

variable "agent_description" {
  description = "The agent description."
  type        = string
  default     = "e2e-rag-agent"
}

variable "agent_action_group" {
  description = "The action group name."
  type        = string
  default     = "e2e-rag-kb"
}

variable "agent_action_group_description" {
  description = "Description of the action group."
  type        = string
  default     = null
}

variable "agent_kb_association_description" {
  description = "Description of what the agent should use the knowledge base for."
  type        = string
  default     = "Use this knowledge base as you are an investment analyst responsible for creating portfolios, researching companies, summarizing documents, and formatting emails."
}

variable "chunking_strategy" {
  type        = string
  description = "Select Chunking strategy"
  default     = "Default chunking"
}

variable "max_tokens" {
  type        = string
  description = "Maximum number of tokens in a chunk"
  default     = "50"
}

variable "overlap_percentage" {
  type        = string
  description = "Percent overlap in each chunk"
  default     = ""
}
