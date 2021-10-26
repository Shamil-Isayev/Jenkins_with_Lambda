import os
import json
import boto3

def lambda_handler(event,context):
  food = os.environ['MY_CONSTANT']
  ip = event['headers']['x-forwarded-for']
  userAgent = event['headers']['user-agent']
  
  sqs = boto3.client("sqs")
  response = sqs.send_message(
      QueueUrl = os.environ['SQS_URL'],
      MessageBody = ip + " - " + userAgent
  )
  body=("Hello there "+ip+" using "+userAgent+", my fav food is "+food)
  
  return {
    'body': body,
    'headers': {
      'Content-Type': 'text/html'
    },
    'statusCode': 200
  }

