# LoRaSensorsVis
This project allows gathering data from sensors to send it through LoRa to [The Things Network](https://www.thethingsnetwork.org). Afterwards, by creating an MQTT client, a safe connection can be established with TTN to retrieve the data and either use it to feed a MySQL database or to visualize it.

## **Hardware used**
1. [The Things Uno](https://www.thethingsnetwork.org/docs/devices/uno/)
2. [WEMOS mini DHT Shield](https://hobbycomponents.com/shields/868-wemos-d1-mini-dht-temphum-shield)
3. [UBLOX NEO-7M](https://www.u-blox.com/en/product/neo-7-series)
4. [GPS Antenna](https://www.adafruit.com/product/960)
5. [Breadboard](https://learn.sparkfun.com/tutorials/how-to-use-a-breadboard)
6. 5 Male-Male wires and 4 Male-Female wires

## **Before running the files**
1. Create an account in The Things Network and register your device following [these instructions](https://www.youtube.com/watch?v=28Fh5OF8ev0). It might also be helpful to watch [TTN's playlist](https://www.youtube.com/watch?v=JrNjY-pGuno&list=PLM8eOeiKY7JVwrBYRHxsf9p0VM_dVapXl).
2. Create your MySQL database.
3. For a safe connection to TTN, you will need [this certificate](https://www.thethingsnetwork.org/docs/applications/mqtt/api.html). Make sure to put it in the folder with the rest of the project's files.

## **Arduino file**
To use [this file](https://github.com/JesusGarcia98/LoRaSensorsVis/blob/master/LoRaNode/LoRaNode.ino), it is necessary to install the following libraries: [TheThingsNetwork](https://github.com/TheThingsNetwork/arduino-device-lib), [SoftwareSerial](https://www.robot-r-us.com/e/995-softwareserial.html), [DHT-sensor-library](https://github.com/adafruit/DHT-sensor-library), [Adafruit_GPS](https://github.com/adafruit/Adafruit_GPS) and [LoraWAN serialization/deserialization](https://github.com/thesolarnomad/lora-serialization).

Essentially, it makes your device connect via OTAA to TTN, creates a new byte payload every 10 seconds which includes temperature, humidity and location data and then, sends it. Includes the wiring instructions for the previously specified hardware.

## **Python file**
To use the [the file](https://github.com/JesusGarcia98/LoRaSensorsVis/blob/master/MQTT.py), it is necessary to install the following libraries: [paho-mqtt](https://pypi.org/project/paho-mqtt/) and [MySQLdb](https://stackoverflow.com/questions/25865270/how-to-install-python-mysqldb-module-using-pip).

Creates a MQTT client that subscribes to a topic and stores all the received messages in a database. Make sure to replace the example values with your own before running it.

## **Processing files**
To use [these files](https://github.com/JesusGarcia98/LoRaSensorsVis/tree/master/SensorsVIZ), it is necessary to install this library: [eclipse-paho](https://www.eclipse.org/paho/downloads.php).

Also creates a MQTT client, however, it works as an Observable which notifies all of its Observers whenever new messages arrive, in order to update their values if it is intended for them. Observers are visualized as an ellipse placed in a roadnetwork. When clicking on their ellipse, a dashboard of its 3 most recent values will be shown.
