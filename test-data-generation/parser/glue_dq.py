import json
import boto3
import logging
from typing import Dict, Any

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize S3 client
s3_client = boto3.client('s3')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler to process S3 events from EventBridge
    """
    try:
        logger.info("Received event: %s", json.dumps(event))

        # Extract bucket and object key from the EventBridge event
        detail = event.get('detail', {})
        bucket_name = detail.get('bucket', {}).get('name')
        object_key = detail.get('object', {}).get('key')

        if not bucket_name or not object_key:
            raise ValueError("Missing bucket name or object key in the event")

        logger.info(f"Processing file {object_key} from bucket {bucket_name}")

        # Get the object from S3
        response = s3_client.get_object(
            Bucket=bucket_name,
            Key=object_key
        )

        # Read the content of the file
        file_content = response['Body'].read().decode('utf-8')
        
        # Process the file content based on the file type
        if object_key.endswith('.json'):
            data = json.loads(file_content)
            logger.info("Parsed JSON data: %s", json.dumps(data))
        elif object_key.endswith('.csv'):
            # Add CSV processing logic here
            logger.info("Processing CSV file")
        else:
            logger.info("Processing text file")

        # Add your business logic here to process the file

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully processed file',
                'bucket': bucket_name,
                'key': object_key
            })
        }

    except Exception as e:
        logger.error("Error processing file: %s", str(e))
        raise
