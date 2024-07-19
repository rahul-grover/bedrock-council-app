locals {
  regions = {
    "apse2" = "ap-southeast-2"
    "use1"  = "us-east-1"
    "euc1"  = "eu-central-1"
  }
  settings = merge(yamldecode(file("application-bedrock-common.yml")), yamldecode(file("${var.TFC_WORKSPACE_NAME}.yml")))

  tags = {
    "region" : local.settings.region
    "env" : local.settings.env
    "nukeoptout" : true
    "owner": "rahul.grover@slalom.com"
  }

  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

provider "aws" {
  # Add other provider configuration, if needed
  region = local.regions[local.settings.region]
}

provider "awscc" {
  # Configuration options
  region = local.regions[local.settings.region]
}

module "opensearch_collection_public" {
  source = "./modules/opensearch-serverless"

  name             = "e2e-rag-collection-public"
  description      = "Public access for ct-kb-aoss-collection collection"
  type             = "VECTORSEARCH"
  standby_replicas = "ENABLED"

  create_access_policy  = true
  create_network_policy = true

  tags = local.tags
}