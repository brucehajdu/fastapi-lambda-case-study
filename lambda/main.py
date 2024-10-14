import json
import boto3
from datetime import datetime

s3 = boto3.client('s3')
bucket_name = 'reorg-bhajdu-case-study'

def lambda_handler(event, context):
    """
    A basic AWS Lambda function that writes a message to an S3 bucket.
    """
    message = {
        'timestamp': datetime.utcnow().isoformat(),
        'message': 'Hello from scheduled Lambda!'
    }
    file_name = f'hello_{datetime.utcnow().strftime("%Y%m%dT%H%M%S")}.json'

    s3.put_object(Bucket=bucket_name, Key=file_name, Body=json.dumps(message))

    return {
        'statusCode': 200,
        'body': json.dumps(message)
    }
