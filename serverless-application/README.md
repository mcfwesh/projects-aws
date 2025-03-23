# Exploring AWS Serverless: Building Scalable Solutions with API Gateway, Lambda, and Step Functions

## Table of Contents

- [Introduction](#introduction)
- [Stage 1: Configure SES](#stage-1-configure-ses)
- [Stage 2: Lambda Execution Role for Email Sending](#stage-2-lambda-execution-role-for-email-sending)
- [Stage 3: State Machines for Flow Control](#stage-3-state-machines-for-flow-control)
- [Stage 4: API Gateway Backend Endpoint](#stage-4-api-gateway-backend-endpoint)
- [Final Stage: Frontend and Email Reminders](#final-stage-frontend-and-email-reminders)
- [Conclusion](#conclusion)

## Introduction

I built a serverless application on AWS, leveraging services like S3, Lambda, SES, SNS, and API Gateway. This project demonstrates how these services can be integrated to create a scalable and robust solution. The application sends email reminders, orchestrated by AWS Step Functions.

## Stage 1: Configure SES

I started by configuring Amazon Simple Email Service (SES) in sandbox mode. This required verifying both sender and receiver email addresses. Sandbox mode is great for testing, but not for production. This setup ensures compliance with AWS email policies.

## Stage 2: Lambda Execution Role for Email Sending

Next, I enabled a Lambda function to send emails. I used AWS CloudFormation to create a stack with an execution role for the Lambda. This role granted permissions to interact with SES, SNS, and access logs for monitoring.

I then wrote the Lambda function in Python using `boto3`. The function sends an email using the configured SES sender and returns a success message.

```python
import boto3, os, json

FROM_EMAIL_ADDRESS = 'mrnate2304+from_2@gmail.com'

ses = boto3.client('ses')

def lambda_handler(event, context):
    # Print event data to logs ..
    print("Received event: " + json.dumps(event))
    # Publish message directly to email, provided by EmailOnly or EmailPar TASK
    ses.send_email( Source=FROM_EMAIL_ADDRESS,
        Destination={ 'ToAddresses': [ event['Input']['email'] ] },
        Message={ 'Subject': {'Data': 'Whiskers Commands You to attend!'},
            'Body': {'Text': {'Data': event['Input']['message']}}
        }
    )
    return 'Success!'

```

## Stage 3: State Machines for Flow Control

I used AWS Step Functions to create state machines that control the application's flow. A CloudFormation template created a role for the state machines, granting permissions for logging and invoking the Lambda function.

The state machine itself was defined using Amazon State Language (ASL) in a JSON document. This included the Amazon Resource Name (ARN) of the Lambda function, allowing the state machine to trigger email sending.

## Stage 4: API Gateway Backend Endpoint

I created a backend endpoint using Amazon API Gateway. This involved several key steps:

1.  **Lambda Function:** A Lambda function acts as the compute backend, receiving data from the frontend and passing it to the state machine. It validates the input data before starting the state machine execution.

```python
import boto3, json, os, decimal

SM_ARN = 'YOUR_STATEMACHINE_ARN'

sm = boto3.client('stepfunctions')

def lambda_handler(event, context):
    # Print event data to logs ..
    print("Received event: " + json.dumps(event))

    # Load data coming from APIGateway
    data = json.loads(event['body'])
    data['waitSeconds'] = int(data['waitSeconds'])

    # Sanity check that all of the parameters we need have come through from API gateway
    # Mixture of optional and mandatory ones
    checks = []
    checks.append('waitSeconds' in data)
    checks.append(type(data['waitSeconds']) == int)
    checks.append('message' in data)

    # if any checks fail, return error to API Gateway to return to client
    if False in checks:
        response = {
            "statusCode": 400,
            "headers": {"Access-Control-Allow-Origin":"*"},
            "body": json.dumps( { "Status": "Success", "Reason": "Input failed validation" }, cls=DecimalEncoder )
        }
    # If none, start the state machine execution and inform client of 2XX success :)
    else:
        sm.start_execution( stateMachineArn=SM_ARN, input=json.dumps(data, cls=DecimalEncoder) )
        response = {
            "statusCode": 200,
            "headers": {"Access-Control-Allow-Origin":"*"},
            "body": json.dumps( {"Status": "Success"}, cls=DecimalEncoder )
        }
    return response

```

2.  **API Gateway Configuration:** I used the REST API model, created a resource, and enabled CORS for cross-origin communication. A POST method was defined and associated with the Lambda function.

3.  **Deployment:** After deploying the API Gateway, AWS provided an endpoint URL for the frontend to use.

## Final Stage: Frontend and Email Reminders

I set up the frontend using an S3 bucket with static web hosting enabled and public access configured via a bucket policy.

The application allows users to enter a message and a delay timer. After the specified delay, the reminder email is sent. I monitored the state machine's execution context and logs to track the process, including interactions between API Gateway and the Lambda functions.

## Conclusion

This project demonstrates a complete serverless solution using AWS services. It highlights the power of serverless architecture and the importance of monitoring and logging for observability. I'm excited to explore further optimizations and possibilities with AWS.
