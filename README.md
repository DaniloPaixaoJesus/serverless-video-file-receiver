# Serverless Video File Receiver

Este projeto implementa uma função **serverless** que é acionada automaticamente após a chegada de um arquivo no **S3**, utilizando o **LocalStack** para emular serviços da AWS.

## 📌 Requisitos
- **Docker** e **Docker Compose**
- **AWS CLI** instalado
- **LocalStack** configurado corretamente

## 🔧 Configuração

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
    --payload '{ "key1": "value1", "key2": "value2" }' \
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
