locals {
  regions = {
    "apse2" = "ap-southeast-2"
    "use1"  = "us-east-1"
    "euc1"  = "eu-central-1"
  }
  settings = merge(yamldecode(file("test-data-bedrock-common.yml")), yamldecode(file("${var.TFC_WORKSPACE_NAME}.yml")))

  tags = {
    "region" : local.settings.region
    "env" : local.settings.env
    "nukeoptout" : true
    "Owner" : "rahul.grover@slalom.com"
  }

  input_prefix = "data"

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

data "aws_bedrock_foundation_model" "agent_test_data" {
  model_id = var.test_data_agent_model_id
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

provider "aws" {
  # Add other provider configuration, if needed
  region = local.regions[local.settings.region]
}

provider "awscc" {
  # Configuration options
  region = local.regions[local.settings.region]
}