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
  default     = "e2e-council-agent"
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

################################################################################
# Bedrock Agent - Travel Agent
################################################################################

variable "agent_model_id_travel" {
  description = "The ID of the foundational model used by the agent."
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "agent_name_travel" {
  description = "The agent name."
  type        = string
  default     = "e2e-travel-agent"
}

variable "agent_description_travel" {
  description = "The agent description."
  type        = string
  default     = "e2e-travel-agent"
}

variable "agent_action_group_travel" {
  description = "The action group name."
  type        = string
  default     = "e2e-travel-kb"
}

variable "agent_action_group_description_travel" {
  description = "Description of the action group."
  type        = string
  default     = null
}

variable "agent_kb_association_description_travel" {
  description = "Description of what the agent should use the knowledge base for."
  type        = string
  default     = "Use this knowledge base as you are an investment analyst responsible for creating portfolios, researching companies, summarizing documents, and formatting emails."
}

variable "chunking_strategy_travel" {
  type        = string
  description = "Select Chunking strategy"
  default     = "Default chunking"
}

variable "max_tokens_travel" {
  type        = string
  description = "Maximum number of tokens in a chunk"
  default     = "50"
}

variable "overlap_percentage_travel" {
  type        = string
  description = "Percent overlap in each chunk"
  default     = ""
}

################################################################################
# Bedrock Guardrails
################################################################################

variable "gr_name" {
  description = "The guardrails name."
  type        = string
  default     = "e2e-rag-gr"
}

variable "gr_blocked_input_messaging" {
  description = "Message to return when the guardrail blocks a prompt."
  type        = string
  default     = "This prompt is not accepted"
}

variable "gr_blocked_output_messaging" {
  description = "Message to return when the guardrail blocks a model response."
  type        = string
  default     = "The model response is not accepted"
}

################################################################################
# EC2
################################################################################

variable "vpc_id" {
  description = "The VPC ID where the EC2 instance will be launched"
  type        = string
  default     = "vpc-0cdfa09bf6e3016fa"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0f71013b2c8bd2c29"
}

variable "ec2_role_name" {
  description = "The name of the IAM role for the EC2 instance"
  type        = string
  default     = "bedrock-role-for-ec2"
}

variable "instance_name" {
  description = "The name tag for the EC2 instance"
  default     = "TerraformBedrockInstance"
}

variable "allowed_ips" {
  description = "List of IP addresses allowed to access the instance"
  type        = list(string)
  default     = ["220.245.130.110/32" , "103.224.52.140/32"]  # Replace with your IP addresses
}

################################################################################
# Bedrock Invocation Logging
################################################################################
variable "invocation_logging" {
  description = "Configuration for the Bedrock invocation logging"
  type = object({
    enabled     = bool
    bucket_name = string
    config = object({
      embedding_data_delivery_enabled = bool
      image_data_delivery_enabled     = bool
      text_data_delivery_enabled      = bool
      cloudwatch_config = object({
        large_data_delivery_s3_config = object({
          key_prefix = string
        })
        log_group_name = string
      })
      s3_config = object({
        key_prefix = string
      })
    })
  })
  default = {
    enabled     = true
    bucket_name = "bedrock-invocation-bucket"
    config = {
      embedding_data_delivery_enabled = true
      image_data_delivery_enabled     = true
      text_data_delivery_enabled      = true
      cloudwatch_config = {
        large_data_delivery_s3_config = {
          key_prefix                   = "bedrock-cloudwatch"
        }
        log_group_name                 = "bedrock-cloudwatch"
      }
      s3_config ={
        key_prefix                   = "bedrock"
      }
    }
  }
}