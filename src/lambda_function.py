import json
import os
import uuid
import boto3
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:4566')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def handler(event, context):
    # Extract request body
    try:
        body = json.loads(event.get('body', '{}'))
    except:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid request body'})
        }
    
    # Create a new item
    item = {
        'id': str(uuid.uuid4()),
        'content': body.get('content', ''),
        'createdAt': datetime.now().isoformat()
    }
    
    # Store in DynamoDB
    table.put_item(Item=item)
    
    # Return success response
    return {
        'statusCode': 201,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(item)
    }