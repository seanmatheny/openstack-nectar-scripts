import logging
import pika
import pprint
import json
USERNAME = 'USERNAME'
PASSWORD = 'PASSWORD'
HOST = 'HOST'
VIRTUAL_HOST = 'VHOST'
def callback(ch, method, properties, body):
        pp = pprint.PrettyPrinter(indent=4)
        json_data = json.loads(body)
        try:
            # Try remove user_data if it exists
            json_data['payload']['args']['instance'].pop('user_data')
        except:
            pass
        #pp.pprint(json_data)
        #works
        print(json_data)
        ##print(["oslo.message"]["publisher_id"])
        #pprint " [x] Received %r" % (body,)
        #do stuff here
        #convert dict_to_json
        ##below two work
        #loaded_json = json.dumps(json_data)
        #print(loaded_json)
        #print(json_data)
        #print(json_data['oslo_message']['publisher_id'])
        #for i in loaded_json:
        #    print("%s: %d" % (x, loaded_json[x]))
        #json_decoded = (json_data).decode("utf-8")
        #example 1 below
        #parsed_json = (json.loads(json_data))
        #print(parsed_json["oslo.message"]["publisher_id"])
        #print(json.dumps(parsed_json, indent=4, sort_keys=True))
        #commented out to put back in queue
        ch.basic_ack(delivery_tag=method.delivery_tag)
def createConnection():
        credentials = pika.PlainCredentials(USERNAME, PASSWORD)
        connection = pika.BlockingConnection(pika.ConnectionParameters(
                HOST,
                5672,
                VIRTUAL_HOST,
                credentials))
        return connection
logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.CRITICAL)
channel = createConnection().channel()
channel.basic_qos(prefetch_count=1)
#channel.basic_consume(callback, queue='auckland-notifications.audit')
channel.basic_consume('auckland-notifications.audit', callback)
channel.start_consuming()
