# bedrock-council-app

This repository contains the Terraform code for deploying the Bedrock Council App, which leverages Amazon Bedrock to provide a conversational AI experience.

## Directory Structure

```
.
├── README.md
├── application-bedrock-common.yml
├── application-bedrock-dev-apse2.yml
├── bedrock.tf
├── iam.tf
├── lambda
│   └── knowledge-base
│       ├── lambda_function.py
│       └── schema.yaml
├── lambda.tf
├── main.tf
├── opensearch.tf
├── outputs.tf
├── prompt-templates
│   ├── agent_instructions.txt
│   └── orchestration.txt
├── s3.tf
├── scripts
│   └── manage_bedrock_agent.sh
├── variables.tf
└── versions.tf
```

## Known Issues and Workarounds

As of today (30/07/2024), there are a few known issues with the Terraform AWS providers related to Bedrock agent management. To work around these issues, we use the [manage_bedrock_agent.sh](scripts/manage_bedrock_agent.sh) script to manage the Amazon Bedrock agent.

The known issues are:

1. **aws_bedrockagent_agent prompt override block causes missing required field**  
   Issue: [hashicorp/terraform-provider-aws#37903](https://github.com/hashicorp/terraform-provider-aws/issues/37903)

2. **aws_bedrockagent_agent resource fails to create due to inconsistent result after apply**  
   Issue: [hashicorp/terraform-provider-aws#37168](https://github.com/hashicorp/terraform-provider-aws/issues/37168)

3. **awscc_bedrock_agent creation unsuccessful with only required inputs**  
   Issue: [hashicorp/terraform-provider-awscc#1572](https://github.com/hashicorp/terraform-provider-awscc/issues/1572)

### OpenSearch Serverless Issue

OpenSearch serverless sometimes fails with the following error:

```
Error: Provider produced inconsistent result after apply
When applying changes to aws_opensearchserverless_access_policy.pipeline, provider "provider[\"registry.terraform.io/hashicorp/aws\"]" produced an unexpected new value: .policy_version: was cty.StringVal("MTcyMjMwNTQ4ODIwMV8y"), but now cty.StringVal("MTcyMjMwNTk1NDczN18z").

This is a bug in the provider, which should be reported in the provider's own issue tracker.
```

The workaround for this issue is to use the `hashicorp/aws` provider version `5.48`.