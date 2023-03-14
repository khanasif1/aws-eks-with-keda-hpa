import boto3
import json
import time
# create a function to add numbers

queue_url = "https://sqs.us-west-1.amazonaws.com/809980971988/keda-queue"


def send_message(message_body):
    print("Start fn send message")
    sqs_client = boto3.client("sqs", region_name="us-west-1")
    
    response = sqs_client.send_message(
    QueueUrl = queue_url,
    MessageBody = message_body
    )
    print(f"messages send: {response}")

    print("End fn send message")

starttime = time.time()
while True:
    t = time.localtime()
    time.sleep(5.0 - ((time.time() - starttime) % 5.0))
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"Start SQS Call : {currenttime}")
    i = 0
    while i < 20:
        i = i+1
        send_message(f"Scale Buddy !!! TIME {currenttime} : COUNT {i}")
    currenttime = time.strftime("%H:%M:%S", t)
    print(f"End SQS Call {currenttime}")
    #time.sleep(5)