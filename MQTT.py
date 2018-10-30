
# coding: utf-8

# In[1]:


import paho.mqtt.client as mqtt
import json
import MySQLdb
import time
import datetime
import dateutil.parser
import base64


# In[2]:


TTN_appEui = '****************'
TTN_appKey  = '********************************'
TTN_user = '<yourUser>'
TTN_password = 'ttn-account-v2.<lotsOfCharacters>'
TTN_tls_path = '<yourCertificate>'
TTN_topic = '<appID>/devices/<devID>/up'


# In[3]:


MySQL_host = '<yourHost>'
MySQL_user = '<yourUser>'
MySQL_password = '<yourPswd>'
MySQL_db = '<yourDB>'


# In[4]:


def on_connect(mqttc, mosq, obj, rc):
    if (rc == 0):
        print('Successful connection with result code: ' + str(rc))
        mqttc.subscribe(TTN_topic)
    else:
        print('Failed connection with result code: ' + str(rc))


# In[5]:


def on_subscribe(mosq, obj, mid, granted_qos):
    print('Subscribed to: ' + TTN_topic)


# In[6]:


def getFieldValues(payloadFields):
    humidity = payloadFields.get('hum')
    temperature = payloadFields.get('temp')
    latitude = payloadFields.get('lat')
    longitude = payloadFields.get('lon')

    return humidity, temperature, latitude, longitude


# In[7]:


def on_message(mqttc, obj, msg):
    try:
        x = json.loads(msg.payload.decode('utf-8'))
        device = str(x['dev_id'])
        humidity, temperature, latitude, longitude = getFieldValues(x['payload_fields'])
        cursor.execute("""INSERT INTO loraNode VALUES (%s, NOW(), %s, %s, %s, %s)""", (device, humidity, temperature, latitude, longitude))
        db.commit()
        print('Message received! Adding to database.')

    except Exception as e:
        print(e)
        db.rollback()
        pass


# In[8]:


mqttc = mqtt.Client()
db = MySQLdb.connect(host=MySQL_host, user=MySQL_user, passwd=MySQL_password, db=MySQL_db)
cursor = db.cursor()

mqttc.on_connect=on_connect
mqttc.on_message=on_message
mqttc.on_subscribe=on_subscribe

mqttc.username_pw_set(TTN_user, TTN_password)
mqttc.tls_set(TTN_tls_path)
mqttc.connect('<yourRegion>.thethings.network', 8883, 10)

mqttc.loop_forever()
db.close()
