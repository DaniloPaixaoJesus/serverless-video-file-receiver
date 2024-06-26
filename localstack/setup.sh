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
awslocal sns create-topic --name transcription-topic

# Empacota a função Lambda
echo "Empacotando a função Lambda..."
zip /docker-entrypoint-initaws.d/lambda_function.zip /docker-entrypoint-initaws.d/lambda_function.py

# Verifica se o arquivo ZIP foi criado
if [ ! -f /docker-entrypoint-initaws.d/lambda_function.zip ]; then
  echo "Erro ao criar o arquivo ZIP da função Lambda."
  exit 1
fi

# Cria a função Lambda
echo "Criando a função Lambda..."
awslocal lambda create-function --function-name receiveVideoFile --zip-file fileb:///docker-entrypoint-initaws.d/lambda_function.zip --handler lambda_function.lambda_handler --runtime python3.8 --role arn:aws:iam::000000000000:role/lambda-role

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

echo "Configuração concluída com sucesso."
