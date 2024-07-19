variable "TFC_WORKSPACE_NAME" {
  description = "Workspace of the infrastructure"
  type        = string
}

# variable "input_bucket_name" {
#   type        = string
#   description = "Provide existing S3 bucket name where data is already stored"
# }

variable "input_document_upload_folder_prefix" {
  type        = string
  description = "Prefix in S3 bucket [optional]"
  default     = ""
}

variable "embed_model" {
  type        = string
  description = "Select Embedding model"
  default     = "amazon.titan-embed-text-v1"
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

variable "vector_store" {
  type        = string
  description = "Select VectorStore"
  default     = "Open-Search-Serverless"
}

variable "collection_name" {
  type        = string
  description = "Name of the Collection"
  default     = "e2e-rag-collection"

  # validation {
  #   condition     = can(regex("^[a-z0-9](-*[a-z0-9])*$", var.collection_name)) && length(var.collection_name) >= 1 && length(var.collection_name) <= 63
  #   error_message = "The collection_name value must be lowercase or numbers with a length of 1-63 characters."
  # }
}

variable "index_name" {
  type        = string
  description = "Index name to be created in vector store"
  default     = "e2e-rag-index"

  # validation {
  #   condition     = can(regex("^[a-z0-9](-*[a-z0-9])*$", var.index_name)) && length(var.index_name) >= 1 && length(var.index_name) <= 63
  #   error_message = "The index_name value must be lowercase or numbers with a length of 1-63 characters."
  # }
}
