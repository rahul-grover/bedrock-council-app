# Create Glue Database
resource "aws_glue_catalog_database" "data_catalog" {
  name        = "test_data_generation_db"
  description = "Database for storing data catalog tables"
}

# Create Glue Table
resource "aws_glue_catalog_table" "data_table" {
  name          = "real_estate_data"
  database_name = aws_glue_catalog_database.data_catalog.name

  parameters = {
    "classification" = "csv" # Change to csv, parquet etc. based on your data format
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_generation_bucket.id}/data/" # Your S3 path
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "OpenCSVSerde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = ","
      }
    }

    # Define your columns here
    columns {
      name = "id"
      type = "bigint"
    }

    columns {
      name = "suburb"
      type = "string"
    }

    columns {
      name = "address"
      type = "string"
    }

    columns {
      name = "rooms"
      type = "bigint"
    }

    columns {
      name = "type"
      type = "string"
    }

    columns {
      name = "price"
      type = "bigint"
    }

    # Add more columns as needed
  }

#   # Optional: Add partitioning
#   partition_keys {
#     name = "id"
#     type = "string"
#   }

#   partition_keys {
#     name = "tid"
#     type = "string"
#   }
}