# Exploring AWS Serverless: Building Scalable Solutions with API Gateway, Lambda

## Table of Contents

- [Introduction](#introduction)
- [Stage 1: Configure SES](#stage-1-configure-ses)
- [Stage 2: Create Execution Role for Lambda to Send Emails on Behalf of the Serverless App](#stage-2-create-execution-role-for-lambda-to-send-emails-on-behalf-of-the-serverless-app)
- [Stage 3: Implementing State Machines to Control the Flow State of the Serverless App](#stage-3-implementing-state-machines-to-control-the-flow-state-of-the-serverless-app)
- [Stage 4: Create a Backend Endpoint for the Application using API Gateway](#stage-4-create-a-backend-endpoint-for-the-application-using-api-gateway)
- [Final Stage: Setting Up the Frontend and Posting a Reminder to an Email](#final-stage-setting-up-the-frontend-and-posting-a-reminder-to-an-email)

## Introduction

In my journey as an avid developer and AWS enthusiast, I've embarked on an exciting project focused on building a serverless application. This endeavor has allowed me to harness the power of various AWS services, such as S3 bucket, Lambda, SES, SNS, and API Gateway, to create a robust and scalable solution. By integrating these services seamlessly, I aim to showcase the versatility and efficiency of serverless architecture in addressing real-world challenges.

## Stage 1: Configure SES

As I embarked on building my serverless application, one of the crucial steps in the initial stage was configuring Amazon Simple Email Service (SES). To ensure a smooth setup process, I opted to run SES in sandbox mode initially. This approach required me to configure and verify both the receiver and sender email addresses through AWS. Although sandbox mode provided a controlled environment for testing and development, it's important to note that it is not recommended for production deployments.

By adhering to this best practice, I ensured that my application's email communication adhered to AWS's stringent policies and guidelines. As I progress through the stages of my project, I will explore how SES seamlessly integrates with other AWS services, enhancing the functionality and user experience of my serverless application.

## Stage 2: Create Execution Role for Lambda to Send Emails on Behalf of the Serverless App

In the next stage of my project, I focused on enabling my Lambda function to send emails on behalf of the serverless application. To streamline this process, I leveraged AWS CloudFormation, which allowed me to swiftly create a stack from a predefined template. Within this stack, I created an execution role specifically tailored for the Lambda function.

This execution role was granted the necessary permissions to seamlessly communicate with Amazon SES, Amazon SNS, and also had access to logs for enhanced monitoring and troubleshooting capabilities. By encapsulating these permissions within the role, I ensured a secure and efficient email sending process.

Moving forward, I proceeded to develop the Lambda function itself using Python. Leveraging the boto3 client, I implemented a function handler that utilized the configured SES sender email. When invoked, this function seamlessly sent the email and returned a success message upon completion.

```
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

Through this stage, I have successfully established the foundation for email communication within my serverless application, enabling seamless integration with SES and other AWS services. In the subsequent stages, I will delve deeper into the application's functionality, expanding its capabilities and exploring additional AWS services.

## Stage 3: Implementing State Machines to Control the Flow State of the Serverless App

In this stage of my project, I focused on implementing state machines to effectively control the flow state of my serverless application. Leveraging the power of AWS Step Functions and Lambda, I created a robust architecture to orchestrate the execution flow seamlessly.

To begin, I utilized AWS CloudFormation to create a dedicated role specifically for the state machines. This role encompassed the necessary permissions, including logging capabilities and interaction with the previously created Lambda function responsible for SES and SNS interactions. By encapsulating these permissions within the role, I ensured a secure and controlled environment for the state machine's execution.

Subsequently, I proceeded to create the state machine itself using the Amazon State Language (ASL). Within the ASL's JSON document, I made sure to include the Amazon Resource Name (ARN) of the Lambda function. This allowed the state machine to effectively invoke and interact with the Lambda function, seamlessly incorporating email sending functionality into the flow state.

By leveraging state machines, I have introduced a level of flexibility and control to my serverless application, enabling precise orchestration of its execution flow. In the upcoming stages, I will explore advanced features and further integration of AWS services, expanding the capabilities and efficiency of my application.

## Stage 4: Create a Backend Endpoint for the Application using API Gateway

In the fourth stage of my project, I focused on establishing a backend endpoint for my application using Amazon API Gateway. This involved a series of steps to enable seamless communication between the frontend and the serverless backend components.

To begin, I created a Lambda function that serves as the compute backend for the API Gateway. This function acts as the entry point, receiving data from the frontend and passing it into the previously defined state machine. The function handler carefully verifies the received data, ensuring that all the required parameters are present and valid. Once validated, the function passes the data to the state machine, triggering the subsequent invocation of the Lambda function responsible for sending emails.

```
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

Following the creation of the Lambda function, I proceeded to configure the API Gateway. Using the REST API model, I built a resource and ensured that CORS (Cross-Origin Resource Sharing) was activated to allow for secure cross-origin communication. Next, I defined the API method, specifically a POST method, on the resource. This method was associated with the underlying Lambda function, effectively linking the endpoint to the serverless backend functionality.

Once the setup was complete, I deployed the API Gateway, and AWS provided me with an endpoint URL. This URL serves as the entry point for the frontend to query, enabling seamless integration between the user interface and the serverless backend.

With the backend endpoint established, I have successfully created a robust communication channel between the frontend and the serverless components of my application. In the subsequent stages, I will continue to enhance the functionality and explore further optimizations using AWS services.

## Final Stage: Setting Up the Frontend and Posting a Reminder to an Email

In the final stage of my project, I focused on setting up the frontend interface and implementing the functionality to send reminders via email. Let's explore the key steps involved in this process.

To begin, I created an S3 bucket and ensured that block public access was disabled. By activating static web hosting, I made the bucket capable of hosting the frontend of my application. To allow public access, I implemented a bucket policy, ensuring that users could interact with the app seamlessly.

After the setup was complete, I opened the application and accessed its user interface. From there, I entered a message along with a delay timer, specifying the amount of time before the message would be sent to the designated email address. In this case, I set the delay timer to 30 seconds.

As time progressed, the application successfully sent the reminder email, indicating the completion of the desired functionality. Throughout this process, the state machine played a pivotal role. To monitor the flow of execution, I closely examined the execution context, which provided valuable insights into the various states that were traversed before successfully sending out the email.

Moreover, logs played a crucial role in capturing important timestamps and events throughout the execution process. By reviewing the logs, I gained visibility into the interactions between the API Gateway and the two Lambda functions (state machines) used for execution.

## Conclusion

With the frontend fully operational and the reminder email successfully sent, I have accomplished my goal of implementing a robust end-to-end solution leveraging AWS services. This project has not only showcased the capabilities of serverless architecture and AWS services but also provided valuable insights into monitoring and logging practices for enhanced observability.

As I conclude this project, I look forward to exploring further possibilities and optimizations in AWS, continuously enhancing the functionality and performance of my applications.
