import json
import os
import uuid
import boto3
from urllib.parse import unquote_plus

# Criando cliente SNS
sns_client = boto3.client("sns")

SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:000000000000:transcription-topic"

def lambda_handler(event, context):
    for record in event.get('Records', []):  # Verifica se existem registros
        try:
            bucket_name = record['s3']['bucket']['name']
            bucket_key = unquote_plus(record['s3']['object']['key'])
            object_size = record['s3']['object'].get('size', 0)  # Pode não existir em eventos de remoção
            event_time = record.get('eventTime', "Desconhecido")

            # Extrai o nome do arquivo
            file_name = os.path.basename(bucket_key)
            
            # Mensagem JSON a ser enviada para o SNS
            message = {
                "bucket-name": bucket_name,
                "bucket-key": bucket_key,
                "file-name": file_name,
                "size": object_size,
                "event-time": event_time,
                "transaction-id": str(uuid.uuid4())
            }
            
            message_json = json.dumps(message)
            print(f"📦 Criacao de mensagem JSON: {message_json}")

            # Publica no SNS e captura a resposta
            response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=message_json,
                Subject="Novo Arquivo Recebido"
            )

            print(f"✅ Mensagem publicada no SNS: {response['MessageId']}")

            # Retorna sucesso para garantir que o evento foi processado corretamente
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": "Mensagem publicada no SNS com sucesso",
                    "sns_message_id": response['MessageId']
                })
            }

        except Exception as e:
            print(f"❌ Erro ao publicar no SNS: {str(e)}")
            return {
                "statusCode": 500,
                "body": json.dumps({"error": str(e)})
            }
