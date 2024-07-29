terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.60.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.7.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.0"
    }
  }
}
