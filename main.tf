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
  }
}

provider "aws" {
  region = local.regions[local.settings.region]
  # Add other provider configuration, if needed
}