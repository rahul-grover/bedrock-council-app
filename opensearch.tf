#create opensearch serverless
resource "aws_opensearchserverless_security_policy" "os_encryption_policy" {
  name        = "${var.collection_name}-enc"
  type        = "encryption"
  description = "Security policy for OpenSearch Serverless"
  policy = jsonencode({
    "Rules" : [
      {
        "ResourceType" : "collection",
        "Resource" : ["collection/${var.collection_name}"],
        "AWSOwnedKey": true
      }
    ]
  })
}
resource "aws_opensearchserverless_security_policy" "os_network_policy" {
  name        = "${var.collection_name}-net"
  type        = "network"
  description = "Security policy for OpenSearch Serverless"
  policy = jsonencode({
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
  })
}

resource "aws_opensearchserverless_access_policy" "name" {
  name        = "${var.collection_name}-access-policy"
  description = "Access policy for OpenSearch Serverless"
  type        = "data"
  policy = jsonencode({
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
          "aoss:CreateIndex"
        ],
        "ResourceType" : "index"
      }
    ],
    "Principal" : ["arn:aws:iam::${local.account_id}:role/${pKbRole}"]
  })
}

resource "aws_opensearchserverless_collection" "kb_os_collection" {
    name = var.collection_name
    description = "Collection for knowledge base"
    type = "VECTORSEARCH"
    tags = local.tags
}