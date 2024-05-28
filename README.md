
event test

{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-east-1",
      "eventTime": "2024-05-25T22:04:17.720Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "A3RRF1OJZHFQGA"
      },
      "requestParameters": {
        "sourceIPAddress": "187.107.8.125"
      },
      "responseElements": {
        "x-amz-request-id": "XPCSWDPRY5NFRTBC",
        "x-amz-id-2": "FTxjFXvUZxBgA1kA0dQp2CkV4UZmecVg8wCCTOACYxN9e5SsENo6lKKXvFFfBkDgXEL7oIZm0Y480raE1rMP+Z/uy7NA6SiS"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "3f694aa9-99a4-4684-9582-f50a81ca1a60",
        "bucket": {
          "name": "app-transcription-bucket",
          "ownerIdentity": {
            "principalId": "A3RRF1OJZHFQGA"
          },
          "arn": "arn:aws:s3:::app-transcription-bucket"
        },
        "object": {
          "key": "video-download-from-front-end2/teste1-11.mkv",
          "size": 536932,
          "eTag": "dfa07282ced2e7f114f926d126b73509",
          "sequencer": "0066526061A07E5426"
        }
      }
    }
  ]
}