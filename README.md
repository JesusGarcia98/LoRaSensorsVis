# LoRaSensorsVis
This project allows to read humidity, temperature and location data from sensors to send it through LoRa to [The Things Network](https://www.thethingsnetwork.org) using Arduino. Afterwards, by creating an MQTT client in Python which safely connects to The Things Network's TLS port, this data can be stored in a previously created MySQL database. Likewise, that MQTT client can also be implemented in Processing to visualize its location - and other values of interest - in a road network.

## **Hardware used**
1. [The Things Uno](https://www.thethingsnetwork.org/docs/devices/uno/)
2. [WEMOS mini DHT Shield](https://hobbycomponents.com/shields/868-wemos-d1-mini-dht-temphum-shield)
3. [UBLOX NEO-7M](https://www.u-blox.com/en/product/neo-7-series)
4. [GPS Antenna](https://www.adafruit.com/product/960)
5. [Breadboard](https://learn.sparkfun.com/tutorials/how-to-use-a-breadboard)
6. 5 Male-Male wires and 4 Male-Female wires

## **Required libraries for Arduino**
To use the [Arduino file](https://github.com/JesusGarcia98/LoRaNode/blob/master/LoRaNode.ino), it is necessary to install the following libraries: [TheThingsNetwork](https://github.com/TheThingsNetwork/arduino-device-lib), [SoftwareSerial](https://www.robot-r-us.com/e/995-softwareserial.html), [DHT-sensor-library](https://github.com/adafruit/DHT-sensor-library) and [Adafruit_GPS](https://github.com/adafruit/Adafruit_GPS).

## **Required libraries for Python**
To use the [Python file](https://github.com/JesusGarcia98/LoRaNode/blob/master/MQTT.py), it is necessary to install the following libraries: [paho-mqtt](https://pypi.org/project/paho-mqtt/) and [MySQLdb](https://stackoverflow.com/questions/25865270/how-to-install-python-mysqldb-module-using-pip).

## **Required libraries for Processing**
To use the [Processing file](https://github.com/JesusGarcia98/LoRaNode/blob/master/MQTT/MQTT.pde), it is necessary to install this library: [eclipse-paho](https://www.eclipse.org/paho/downloads.php).

## **Before running the files**
Create an account in [The Things Network](https://www.thethingsnetwork.org) and register your device following [these instructions](https://www.youtube.com/watch?v=28Fh5OF8ev0).

Create your MySQL database.

For a safe connection to TTN, you will need to find a TLS certificate. You can find it in [TTN's MQQT API](https://www.thethingsnetwork.org/docs/applications/mqtt/api.html). Make sure to put it in the folder with the rest of the project's files.

## **Arduino file**
The one to rule them all. Includes the instructions for the appropriate wiring, along with the explanation to gather data from the sensors and send it to TTN, which is needed for the rest of the files.

For a better understanding of the way to connect to TTN and send data as a payload of bytes, watch [this video](https://www.youtube.com/watch?v=-VaW9bBVrYM&t=62s). Also, have a look at [this project](https://learn.adafruit.com/adafruit-ultimate-gps?view=all) to see how the GPS library works.

## **Python file**
Includes the explanation of how to safely connect to TTN, retrieve the data as a byte payload, decode it and send it to your MySQL database.

For a better understanding of how MQTT works, you can check [this](https://www.hivemq.com/mqtt/).

## **Processing file**
Safely connects to TTN through its TSL/SSL port and allows subscription to retrieve data. The visualization in the road network is still work in progress.
