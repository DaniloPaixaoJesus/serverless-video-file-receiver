# Serverless Video File Receiver

Este projeto implementa uma função **serverless** que é acionada automaticamente após a chegada de um arquivo no **S3**, utilizando o **LocalStack** para emular serviços da AWS.

## 📌 Requisitos
- **Docker** e **Docker Compose**
- **AWS CLI** instalado
- **LocalStack** configurado corretamente

## 🔧 Configuração

Crie a rede externa no Docker para que os recursos criados no serviço LOCALSTACK seja compartilhado em diferentes docker-compose
```sh
docker network create localstack-network
```

Antes de iniciar o LocalStack, configure as credenciais de teste:

```sh
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
```

Garanta que o **arquivo `setup.sh` tenha permissão de execução**:

```sh
chmod +x setup.sh
```

## 🚀 Verificação dos Recursos Criados

Liste os buckets S3:

```sh
aws --endpoint-url=http://localhost:4566 s3api list-buckets
```

Verifique a configuração de CORS no bucket:

```sh
aws --endpoint-url=http://localhost:4566 s3api get-bucket-cors --bucket transcription-bucket
```

Liste os tópicos SNS criados:

```sh
aws --endpoint-url=http://localhost:4566 sns list-topics --query "Topics[?contains(TopicArn, 'transcription-topic')].TopicArn" --output text
```

Liste todas as funções Lambda disponíveis:

```sh
aws --endpoint-url=http://localhost:4566 lambda list-functions --query "Functions[].FunctionName"
```

Verifique se a função Lambda `receiveVideoFile` existe:

```sh
aws --endpoint-url=http://localhost:4566 lambda list-functions --query "Functions[?FunctionName=='receiveVideoFile'].FunctionName" --output text
```

Verifique as permissões da Lambda:

```sh
aws --endpoint-url=http://localhost:4566 lambda get-policy --function-name receiveVideoFile --query "Policy" --output text
```

## 📡 Testando a Execução da Lambda

Execute a Lambda manualmente:

```sh
aws --endpoint-url=http://localhost:4566 lambda invoke \
    --function-name receiveVideoFile \
    --payload '{ "Records": [ { "s3": { "bucket": { "name": "transcription-bucket" }, "object": { "key": "video-download-from-front-end/test.mp4", "size": 12345 } }, "eventTime": "2025-03-18T12:00:00Z" } ] }' \
    response.json
```

Verifique a saída:

```sh
cat response.json
```

## 📂 Teste com Upload para S3

Faça o upload de um arquivo para o bucket e dispare a função Lambda automaticamente:

```sh
aws --endpoint-url=http://localhost:4566 s3 cp exemplo.mp4 s3://transcription-bucket/video-download-from-front-end/
```

Verifique se o objeto foi carregado no bucket

```sh
aws --endpoint-url=http://localhost:4566 s3 ls s3://transcription-bucket
aws --endpoint-url=http://localhost:4566 s3api list-objects \
    --bucket transcription-bucket \
    --output json

```

## 📂 Verifique se a mensagem foi publicada no SNS

Verifique a mensagem no tópico SNS

```sh
aws --endpoint-url=http://localhost:4566 sns list-subscriptions-by-topic \
    --topic-arn arn:aws:sns:us-east-1:000000000000:transcription-topic
```

Caso você tenha assinado uma fila SQS, veja se a mensagem chegou:

```sh
aws --endpoint-url=http://localhost:4566 sqs receive-message \
    --queue-url http://localhost:4566/000000000000/transcription-queue
```
