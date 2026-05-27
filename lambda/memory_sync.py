import json
import boto3
import os
from datetime import datetime

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

# Environment variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'hermes-memory-vault')
BUCKET_NAME = os.environ.get('S3_BUCKET', 'hermes-skills-archive')

def lambda_handler(event, context):
    """
    Hermes Agent Memory Vault Sync
    Receives payloads from Hermes Agent containing skills, MEMORY.md updates, 
    or session archives, and syncs them to DynamoDB and S3 for persistent cloud storage.
    """
    try:
        # Parse incoming request from API Gateway
        body = json.loads(event.get('body', '{}'))
        memory_type = body.get('type')
        agent_id = body.get('agent_id', 'default-hermes')
        
        if not memory_type:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Missing memory type'})}
            
        table = dynamodb.Table(TABLE_NAME)
        timestamp = datetime.utcnow().isoformat()
        
        # Handle MEMORY.md and USER.md updates (Prompt Memory)
        if memory_type == 'prompt_memory':
            content = body.get('content')
            file_name = body.get('file_name') # MEMORY.md or USER.md
            
            table.put_item(
                Item={
                    'AgentId': agent_id,
                    'MemoryKey': f"prompt#{file_name}",
                    'Content': content,
                    'LastUpdated': timestamp
                }
            )
            return {'statusCode': 200, 'body': json.dumps({'message': f'Prompt memory {file_name} synced'})}
            
        # Handle Skill creation/updates (Procedural Memory)
        elif memory_type == 'skill':
            skill_name = body.get('skill_name')
            skill_content = body.get('content')
            
            # Store skill metadata in DynamoDB
            table.put_item(
                Item={
                    'AgentId': agent_id,
                    'MemoryKey': f"skill#{skill_name}",
                    'Summary': body.get('description', ''),
                    'LastUpdated': timestamp
                }
            )
            
            # Store actual skill markdown file in S3
            s3_key = f"{agent_id}/skills/{skill_name}.md"
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=skill_content,
                ContentType='text/markdown'
            )
            return {'statusCode': 200, 'body': json.dumps({'message': f'Skill {skill_name} synced to S3 and DynamoDB'})}
            
        # Handle Session Archive sync (Episodic Memory)
        elif memory_type == 'session_archive':
            session_id = body.get('session_id')
            sqlite_dump = body.get('sqlite_base64') # Base64 encoded sqlite dump
            
            s3_key = f"{agent_id}/sessions/{session_id}.sqlite"
            # In a real scenario, we'd decode base64 before saving
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=sqlite_dump
            )
            return {'statusCode': 200, 'body': json.dumps({'message': f'Session {session_id} archived to S3'})}
            
        else:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid memory type'})}
            
    except Exception as e:
        print(f"Error syncing memory: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': 'Internal server error'})}
