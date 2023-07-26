import asyncio
import os
# import uuid
from azure.servicebus.aio import ServiceBusClient
from azure.servicebus import ServiceBusMessage

NAMESPACE_CONNECTION_STR = os.environ['NAMESPACE_CONNECTION_STR']
TOPIC_NAME = "entry"
# SESSION_ID = str(uuid.uuid4())

async def send_a_list_of_messages(sender):
    # Create a list of messages
    messages = [ServiceBusMessage(body="Message in list") for _ in range(1000)]
    # send the list of messages to the topic
    await sender.send_messages(messages)
    print("Sent 1000 messages")


async def run():
    # create a Service Bus client using the connection string
    async with ServiceBusClient.from_connection_string(
            conn_str=NAMESPACE_CONNECTION_STR,
            logging_enable=True) as servicebus_client:
        # Get a Topic Sender object to send messages to the topic
        sender = servicebus_client.get_topic_sender(topic_name=TOPIC_NAME)
        async with sender:
            for n in range(10):
                # Send a list of messages
                await send_a_list_of_messages(sender)

asyncio.run(run())
print("Done sending messages")
print("-----------------------")
