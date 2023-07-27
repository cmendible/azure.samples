import json
import logging
import os
import azure.functions as func

from azure.servicebus import ServiceBusClient, ServiceBusSender, ServiceBusMessage

connstr = os.environ['AzureServiceBusConnectionString']
queue_name = "backlog"

serviceBusSender = None


def main(msg: func.ServiceBusMessage) -> str:
    result = json.dumps({
        'message_id': msg.message_id,
        'body': msg.get_body().decode('utf-8'),
        'content_type': msg.content_type,
        'delivery_count': msg.delivery_count,
        'expiration_time': (msg.expiration_time.isoformat() if
                            msg.expiration_time else None),
        'label': msg.label,
        'partition_key': msg.partition_key,
        'reply_to': msg.reply_to,
        'reply_to_session_id': msg.reply_to_session_id,
        'scheduled_enqueue_time': (msg.scheduled_enqueue_time.isoformat() if
                                   msg.scheduled_enqueue_time else None),
        'session_id': msg.session_id,
        'time_to_live': msg.time_to_live,
        'to': msg.to,
        'user_properties': msg.user_properties,
    })

    logging.info(result)

    mesage = ServiceBusMessage("Single message")

    # This is the way to go if you need to modify the message metadata before sending it.
    getOrCreateServiceBusClientSender().send_messages(mesage)


def getOrCreateServiceBusClientSender() -> ServiceBusSender:
    global serviceBusSender
    if serviceBusSender is None:
        client = ServiceBusClient.from_connection_string(connstr)
        serviceBusSender = client.get_queue_sender(queue_name)
    return serviceBusSender
