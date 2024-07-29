################################################################################
# Encryption Policy
################################################################################

resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "${var.collection_name}-enc"
  type        = "encryption"
  description = "Encryption policy for ${var.collection_name} collection"
  policy = jsonencode({
    "Rules" : [
      {
        "ResourceType" : "collection",
        "Resource" : ["collection/${var.collection_name}"]
      }
    ]
    "AWSOwnedKey" : true
  })
}

################################################################################
# Network Policy
################################################################################

resource "aws_opensearchserverless_security_policy" "network" {
  name        = "${var.collection_name}-net"
  type        = "network"
  description = "Security policy for OpenSearch Serverless"
  policy = jsonencode([
    {
      "Description" : "Public access for ct-kb-aoss-collection collection",
      "AllowFromPublic" : true,
      "Rules" : [
        {
          "ResourceType" : "dashboard",
          "Resource" : ["collection/${var.collection_name}"],
        },
        {
          "ResourceType" : "collection",
          "Resource" : ["collection/${var.collection_name}"],
        }
      ]
    }
  ])
}

################################################################################
# Access Policy
################################################################################

resource "aws_opensearchserverless_access_policy" "bedrock_kb" {
  name        = "${var.collection_name}-kb-access"
  description = "Access policy for ${var.collection_name} collection"
  type        = "data"
  policy = jsonencode([{
    "Description" : "Access policy for ct-kb-aoss-collection collection",
    "Rules" : [
      {
        "Resource" : ["collection/${var.collection_name}"],
        "Permission" : [
          "aoss:DescribeCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:CreateCollectionItems"
        ],
        "ResourceType" : "collection"
      },
      {
        "Resource" : ["index/${var.collection_name}/*"],
        "Permission" : [
          "aoss:DescribeIndex",
          "aoss:UpdateIndex",
          "aoss:CreateIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ],
        "ResourceType" : "index"
      }
    ],
    Principal = [
      aws_iam_role.bedrock_kb.arn
    ]
  }])
}

resource "aws_opensearchserverless_access_policy" "pipeline" {
  name        = "${var.collection_name}-cicd-access"
  description = "Access policy for ${var.collection_name} collection"
  type        = "data"
  policy = jsonencode([{
    "Description" : "Access policy for ct-kb-aoss-collection collection",
    "Rules" : [
      {
        "Resource" : ["collection/${var.collection_name}"],
        "Permission" : [
          "aoss:DescribeCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:CreateCollectionItems"
        ],
        "ResourceType" : "collection"
      },
      {
        "Resource" : ["index/${var.collection_name}/*"],
        "Permission" : [
          "aoss:DescribeIndex",
          "aoss:UpdateIndex",
          "aoss:CreateIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument",
          "aoss:DeleteIndex"
        ],
        "ResourceType" : "index"
      }
    ],
    Principal = [
      # data.aws_caller_identity.current.arn,
      "arn:aws:sts::${local.account_id}:assumed-role/*${var.pipeline_iam_role}*",
      "arn:aws:iam::${local.account_id}:role/${var.pipeline_iam_role}"
    ]
  }])
}

################################################################################
# Collection
################################################################################

resource "aws_opensearchserverless_collection" "this" {
  name        = var.collection_name
  description = "Collection for knowledge base"
  type        = "VECTORSEARCH"
  tags        = local.tags

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.bedrock_kb,
    aws_opensearchserverless_access_policy.pipeline
  ]
}

################################################################################
# Index
################################################################################

provider "opensearch" {
  url         = aws_opensearchserverless_collection.this.collection_endpoint
  healthcheck = false # Client health check does not work with OpenSearch Serverless
}

resource "opensearch_index" "this" {
  name                           = var.vector_index_name
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "${var.vector_index_name}": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [aws_opensearchserverless_collection.this]

  # [BUG] Index replacement with dynamic properties
  # https://github.com/opensearch-project/terraform-provider-opensearch/issues/175#issuecomment-2037404360
  lifecycle {
    ignore_changes = [mappings]
  }
}