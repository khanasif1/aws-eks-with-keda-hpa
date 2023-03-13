import boto3
import json
import time
# create a function to add numbers

queue_url = "https://sqs.us-west-1.amazonaws.com/809980971988/keda-queue"


def receive_message():
    print("Start fn receive message")
    sqs_client = boto3.client("sqs", region_name="us-west-1")
    response = sqs_client.receive_message(
        QueueUrl= queue_url,
        AttributeNames=[
        'SentTimestamp'
        ],
        MaxNumberOfMessages=1,
        MessageAttributeNames=[
        'All'
        ],
        WaitTimeSeconds=0,
        VisibilityTimeout=0
    )

    print(f"Number of messages received: {len(response.get('Messages', []))}")
    
    #for message in response.get("Messages", []):
    if len(response.get('Messages', [])) != 0:
        message = response['Messages'][0]
        message_body = message["Body"]
        print(f"message_body : {message_body}")

        receipt_handle = message['ReceiptHandle']
        
        print(f"Receipt Handle: {message['ReceiptHandle']}")
        print(f"Deleting Message : {message_body}")
        # Delete received message from queue
        sqs_client.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=receipt_handle
        )
    print("End fn receive message")

starttime = time.time()
while True:
    t = time.localtime()
    time.sleep(5.0 - ((time.time() - starttime) % 5.0))
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"Start SQS Call : {currenttime}")
    receive_message()
    '''i = 0
    while i < 20:
        i = i+1'''
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"End SQS Call {currenttime}")
    #time.sleep(5)