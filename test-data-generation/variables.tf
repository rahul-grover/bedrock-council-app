variable "TFC_WORKSPACE_NAME" {
  description = "Workspace of the infrastructure"
  type        = string
}

################################################################################
# Bedrock Agent - Test Data Agent
################################################################################

variable "test_data_agent_model_id" {
  description = "The ID of the foundational model used by the agent."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "test_data_agent_name" {
  description = "The agent name"
  type        = string
  default     = "bedrock-test-data-agent"
}

variable "test_data_agent_description" {
  description = "The agent description"
  type        = string
  default     = "This agent would help generate Test Data based on an input DQDL file"
}

variable "test_data_chunking_strategy" {
  type        = string
  description = "Select Chunking strategy"
  default     = "Default chunking"
}

variable "test_data_max_tokens" {
  type        = string
  description = "Maximum number of tokens in a chunk"
  default     = "50"
}

variable "test_data_overlap_percentage" {
  type        = string
  description = "Percent overlap in each chunk"
  default     = ""
}