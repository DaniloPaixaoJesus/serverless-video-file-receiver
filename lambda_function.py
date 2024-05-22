import json
import os
import boto3
from urllib.parse import unquote_plus

s3_client = boto3.client('s3', endpoint_url='http://localstack:4566')
sns_client = boto3.client('sns', endpoint_url='http://localstack:4566')
topic_arn = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = unquote_plus(record['s3']['object']['key'])
        object_size = record['s3']['object']['size']
        event_time = record['eventTime']
        
        # Generate UUID
        new_uuid = str(uuid.uuid4())
        
        # Extract file extension and base name
        ext = os.path.splitext(object_key)[1]
        base_name = os.path.splitext(object_key)[0]
        
        # Create new object key
        new_object_key = f"{base_name}_{new_uuid}{ext}"
        
        # Rename the object in S3
        copy_source = {'Bucket': bucket_name, 'Key': object_key}
        try:
            s3_client.copy_object(CopySource=copy_source, Bucket=bucket_name, Key=new_object_key)
            s3_client.delete_object(Bucket=bucket_name, Key=object_key)
        except Exception as e:
            print(f"Erro ao renomear o objeto no S3: {e}")
            raise e
        
        # Create message to send to SNS
        message = {
            "bucket-name": bucket_name,
            "bucket-key": new_object_key,
            "size": object_size,
            "event-time": event_time,
            "uuid": new_uuid
        }
        
        message_json = json.dumps(message)
        
        # Publish the message to SNS
        try:
            response = sns_client.publish(
                TopicArn=topic_arn,
                Message=message_json
            )
        except Exception as e:
            print(f"Erro ao publicar mensagem no SNS: {e}")
            raise e
        
        print(f"Mensagem publicada com sucesso no SNS: {message}")

    return {
        'statusCode': 200,
        'body': json.dumps('Processamento concluído com sucesso.')
    }
