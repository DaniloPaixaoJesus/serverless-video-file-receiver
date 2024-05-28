import json
import os
import uuid
from urllib.parse import unquote_plus

def lambda_handler(event, context):
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        bucket_key = unquote_plus(record['s3']['object']['key'])
        object_size = record['s3']['object']['size']
        event_time = record['eventTime']

        # Extract the file name from the bucket key
        file_name = os.path.basename(bucket_key)
        print("Receiving file from front-end:")
        print(f"file_name - {file_name}")
        print(f"bucket_name - {bucket_name}")
        print(f"bucket_key - {bucket_key}")

        # Create message to send to SNS
        message = {
            "bucket-name": bucket_name,
            "bucket-key": bucket_key,
            "file-name": file_name,
            "size": object_size,
            "event-time": event_time,
            "transaction-id": str(uuid.uuid4())
        }
        
        #message_json = json.dumps(message)

    return message
