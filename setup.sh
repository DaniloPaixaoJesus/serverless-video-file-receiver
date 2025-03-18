#!/bin/bash

# Espera a inicialização do LocalStack
echo "Esperando o LocalStack iniciar..."
sleep 15

# Cria o bucket S3
echo "Criando o bucket S3..."
awslocal s3api create-bucket --bucket transcription-bucket

# Configura o CORS no bucket devido ao LocalStack ser localhost
echo "Configurando o CORS no bucket..."
awslocal s3api put-bucket-cors --bucket transcription-bucket --cors-configuration '{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"]
    }
  ]
}'

# Cria o tópico SNS
echo "Criando o tópico SNS..."
TOPIC_ARN=$(awslocal sns create-topic --name transcription-topic --query 'TopicArn' --output text)
echo "Tópico SNS criado: $TOPIC_ARN"


# Criar a fila SQS transcription-queue
echo "Criando a fila SQS..."
QUEUE_URL=$(awslocal sqs create-queue --queue-name transcription-queue --query 'QueueUrl' --output text)
echo "Fila SQS criada: $QUEUE_URL"


# Obter o ARN da fila SQS
QUEUE_ARN=$(awslocal sqs get-queue-attributes \
    --queue-url $QUEUE_URL \
    --attribute-names QueueArn \
    --query 'Attributes.QueueArn' --output text)
echo "ARN da Fila SQS: $QUEUE_ARN"


# Inscrever a fila SQS no tópico SNS
echo "Inscrevendo a fila SQS no tópico SNS..."
awslocal sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint $QUEUE_ARN
echo "Fila SQS inscrita com sucesso no tópico SNS."


# Permitir que o SNS publique mensagens na fila SQS
echo "Configurando permissões para o SNS enviar mensagens para a SQS..."
awslocal sqs set-queue-attributes \
    --queue-url $QUEUE_URL \
    --attributes '{
      "Policy": "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": \"*\", \"Action\": \"SQS:SendMessage\", \"Resource\": \"'$QUEUE_ARN'\", \"Condition\": {\"ArnEquals\": {\"aws:SourceArn\": \"'$TOPIC_ARN'\"}}}]}"}'
echo "Permissões configuradas."


echo "Verificando a existência do arquivo lambda_function.py..."
ls -lah /docker-entrypoint-initaws.d/


echo "Empacotando a função Lambda..."
cd /docker-entrypoint-initaws.d || exit 1
#zip lambda_function.zip lambda_function.py
zip -r /docker-entrypoint-initaws.d/lambda_function.zip lambda_function.py


# Verifica se o arquivo foi criado
if [ ! -f lambda_function.zip ]; then
  echo "❌ Erro ao criar o arquivo ZIP da função Lambda."
  exit 1
fi


# Cria a função Lambda
echo "Criando a função Lambda..."
awslocal lambda create-function --function-name receiveVideoFile --zip-file fileb://lambda_function.zip --handler lambda_function.lambda_handler --runtime python3.8 --role arn:aws:iam::000000000000:role/lambda-role


# Espera a função Lambda estar ativa
echo "Esperando a função Lambda estar ativa..."
awslocal lambda wait function-active-v2 --function-name receiveVideoFile


# Adiciona permissão para que o S3 invoque a função Lambda
echo "Adicionando permissão para que o S3 invoque a função Lambda..."
awslocal lambda add-permission --function-name receiveVideoFile --principal s3.amazonaws.com --statement-id some-unique-id --action "lambda:InvokeFunction" --source-arn arn:aws:s3:::transcription-bucket --source-account 000000000000


# Configura a notificação do bucket S3
echo "Configurando a notificação do bucket S3..."
awslocal s3api put-bucket-notification-configuration --bucket transcription-bucket --notification-configuration file:///docker-entrypoint-initaws.d/notification.json


if [ $? -ne 0 ]; then
  echo "Erro ao configurar a notificação do bucket S3."
  exit 1
fi


echo "Adicionando permissão para a Lambda publicar no SNS..."
awslocal lambda add-permission \
    --function-name receiveVideoFile \
    --principal sns.amazonaws.com \
    --statement-id allow-lambda-sns \
    --action "lambda:InvokeFunction" \
    --source-arn $TOPIC_ARN


echo "Configuração concluída com sucesso."
