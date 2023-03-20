import boto3
import json
import time
import uuid
# create a function to add numbers
starttime = time.time()

queue_url = "https://sqs.us-west-1.amazonaws.com/809980971988/keda-queue"


def receive_message():
    try:
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

            save_data(message_body)

            receipt_handle = message['ReceiptHandle']
            
            print(f"Receipt Handle: {message['ReceiptHandle']}")
            print(f"Deleting Message : {message_body}")
            # Delete received message from queue
            sqs_client.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=receipt_handle
            )
        print("End fn receive message")
    except Exception as ex:
        print(f"Error happened in receive_message : {ex} ")
    

def save_data(_message):
    try:
        _id=str(uuid.uuid1())
        print(f"id:{_id}")
        dynamodb = boto3.resource('dynamodb', region_name="us-west-1")
        table = dynamodb.Table('payments')

        response = table.put_item(
            Item={
            'id': _id,
            'data': _message
            }
        )
        status_code = response['ResponseMetadata']['HTTPStatusCode']
        print(f"Data Save Status : {status_code}")
    except Exception as error:
        print(f"Error has happened : {error}")

    
      

while True:
    t = time.localtime()
    time.sleep(15.0 - ((time.time() - starttime) % 15.0)) #sleep for 15 sec
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"Start SQS Call : {currenttime}")

    receive_message()
    #save_data("hi there")
    '''i = 0
    while i < 20:
        i = i+1'''
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"End SQS Call {currenttime}")
