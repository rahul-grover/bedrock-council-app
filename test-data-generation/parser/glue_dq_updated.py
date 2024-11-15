import json
import os
import boto3
import logging
import time
from typing import Dict, Any
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
glue_client = boto3.client('glue')
s3_client = boto3.client('s3')

def wait_for_dq_task(run_id: str) -> Dict:
    """
    Wait for the Data Quality task to complete and return the results
    """
    while True:
        response = glue_client.get_data_quality_rule_recommendation_run(
            RunId=run_id
        )
        print('response from recommendation run:', response)
        status = response['Status']
        if status in ['SUCCEEDED', 'FAILED', 'TIMEOUT', 'ERROR']:
            return response
        
        time.sleep(10)  # Wait for 10 seconds before checking again

def create_dq_recommendation_run(database_name: str, table_name: str, role_arn: str) -> str:
    """
    Create a Data Quality ruleset based on recommendations
    """
    try:
        print('inside create_dq_ruleset')
        print(database_name, table_name)
        # Get rule recommendations
        response = glue_client.start_data_quality_rule_recommendation_run(
            DataSource={
                'GlueTable': {
                    'DatabaseName': database_name,
                    'TableName': table_name
                }
            },
            Role=role_arn,
        )
        print('Get dQ rule done')
        print('response:',response)
        return response['RunId']
        
    except ClientError as e:
        logger.error(f"Error creating ruleset: {str(e)}")
        raise

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler to run Glue Data Quality on S3 files
    """
    try:
        logger.info("Received event: %s", json.dumps(event))

        # Extract configuration from environment variables
        database_name = os.environ['GLUE_DATABASE_NAME']
        table_name = os.environ['GLUE_TABLE_NAME']
        output_location = os.environ['OUTPUT_S3_LOCATION']
        role_arn = os.environ['ROLE_ARN']
        
        # Extract S3 details from the event
        detail = event.get('detail', {})
        source_bucket = detail.get('bucket', {}).get('name')
        source_key = detail.get('object', {}).get('key')

        if not source_bucket or not source_key:
            raise ValueError("Missing source bucket or key in the event")

        logger.info(f"Processing file {source_key} from bucket {source_bucket}")
        logger.info(f"Environment properties : db_name {database_name}, table_name {table_name}")

        # Create or get existing ruleset
        run_id = create_dq_recommendation_run(database_name, table_name, role_arn)
        
        # # Start the Data Quality task
        # response = glue_client.start_data_quality_task_run(
        #     DatabaseName=database_name,
        #     TableName=table_name,
        #     RulesetId=ruleset_id,
        #     AdditionalRunOptions={
        #         'CloudWatchMetricsEnabled': True,
        #         'ResultsS3Prefix': output_location
        #     }
        # )
        
        # task_run_id = response['TaskRunId']
        logger.info(f"Started Data Quality recommendation run with ID: {run_id}")
        
        # Wait for the task to complete
        result = wait_for_dq_task(run_id)
        
        if result['Status'] == 'SUCCEEDED':
            # Get the results
            results = glue_client.get_data_quality_results(
                TaskRunId=task_run_id
            )
            recommended_rule_set = response['RecommendedRuleset']
            # Store results in S3
            result_key = f"{output_location}/output/dq_results_{task_run_id}.txt"
            s3_client.put_object(
                Bucket=source_bucket,
                Key=result_key,
                Body=recommended_rule_set
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Data Quality check completed successfully',
                    'taskRunId': task_run_id,
                    'resultsLocation': f"s3://{source_bucket}/{result_key}"
                })
            }
        else:
            raise Exception(f"Data Quality task failed with status: {result['Status']}")

    except Exception as e:
        logger.error(f"Error processing file: {str(e)}")
        raise
