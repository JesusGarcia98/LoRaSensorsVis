import java.util.Observer;


/**
 * Kind of a facade to create and manage all the sensors
 * @author    Guillem Francisco
 * @modified  Jesús García
 * @version   0.1
 */
public class Sensors {
  private final ArrayList<Sensor> SENSORS = new ArrayList();
  private Lanes roadnetwork;
  private boolean drawHistoricals;


  /**
   * Initiate sensors facade
   * @param file    JSON file direction
   * @param client  MQTTClient in which we will add the observers
   * @param roads   Lanes Object in which the sensors will be placed
   */
  public Sensors(String file, MQTTClient client, Lanes roads) {
    roadnetwork = roads;
    load(file, client);
  }


  /**
   * Create sensors Objects from JSON file and add observers to MQTTClient
   * @param file  JSON file direction
   * @param client  MQTTClient in which we will add the observers
   */
  private void load(String file, MQTTClient client) {
    JSONObject object = loadJSONObject(file);
    JSONArray sensors = object.getJSONArray("sensors");

    for (int i = 0; i < sensors.size(); i++) {
      JSONObject sensor = sensors.getJSONObject(i);

      String id = sensor.getString("deviceID");
      String type = sensor.getString("type");
      JSONArray variables = sensor.getJSONArray("variables");
      String[] vrbls = {};

      for (int j = 0; j < variables.size(); j++) {
        vrbls = append(vrbls, variables.getString(j));
      }

      if (type.equals("GPSTempHum")) {
        GPSTempHum newSensor = new GPSTempHum(id, vrbls, roadnetwork);
        HistoricalSensor newHistorical = new HistoricalSensor(id, vrbls, roadnetwork);

        SENSORS.add(newSensor);
        SENSORS.add(newHistorical);

        client.addObserver(newSensor);
        client.addObserver(newHistorical);
      }
    }
  }


  /**
   *  Toggle the draw methods for historical and non-historical sensors
   */
  public void toggleHistoricals() {
    drawHistoricals = !drawHistoricals;
  }


  /**
   *  Draw either non-historical or historical sensor Objects on the sketch
   *  @param canvas  The canvas Object to draw on
   *  @param size    Size of the ellipses that represent sensor Objects 
   */
  public void draw(Canvas canvas, int size) {
    for (Sensor sensor : SENSORS) {
      if (sensor.isHistorical && drawHistoricals) sensor.draw(canvas, size);
      else if (!sensor.isHistorical && !drawHistoricals) sensor.draw(canvas, size);
    }
  }
}


/**
 * Abstract Observer object that represents a generic sensor. It has the specified varaibles and
 * updates them when a new value is collected
 * @author    Guillem Francisco
 * @modified  Jesús García
 * @version   0.1
 */
public abstract class Sensor implements Observer {
  protected final String ID;
  protected FloatDict variablesValues = new FloatDict();
  protected final Lanes roadnetwork;
  protected boolean isHistorical;


  /**
   * Initiate sensor with parameters that define itself
   * @param id           ID of the lane
   * @param variables    Variables that the sensor is gathering
   * @param roadnetwork  Roads of the zone
   */
  public Sensor(String id, String[] variables, Lanes roadnetwork) {
    ID = id;
    this.roadnetwork = roadnetwork;
    createDict(variables);
  }


  /**
   * Initiate dictionary with the keys provided in the constructor
   * @param sensorVariables String array with all the keys
   */
  private void createDict (String[] sensorVariables) {
    for (int i = 0; i < sensorVariables.length; i++) {
      variablesValues.set(sensorVariables[i], 0);
    }
  }


  /**
   * Return dictionary with variables and values of each
   * @returns Dictionary with the variables and values
   */
  public FloatDict getVariablesValues() {
    return variablesValues;
  }


  /**
   * Observer function that updates values of the dictionary
   * @param obs Observable from which we are getting the data
   * @param obj Object the Observable is sending
   */
  public abstract void update(Observable obs, Object obj);


  /**
   * Function to visualize the sensor
   * @param canvas  The canvas Object to draw on
   * @param size    Size of the ellipse representing the sensor
   */
  public abstract void draw(Canvas canvas, int size);
}


/**
 * Extended object represents a sensor with gps, temperature and humidity variables
 * @author    Guillem Francisco
 * @modified  Jesús García
 * @version   0.1
 */
public class GPSTempHum extends Sensor {
  private PVector lastPosition, currPosition;
  private float rad = random(0, 20);
  private boolean decreasing = true;


  /**
   * Initiate sensor with parameters that define itself
   * @param id          ID of the lane
   * @param variables   Variables that the sensor is gathering
   * @param roadnetwork Roads of the zone
   */
  public GPSTempHum(String id, String[] variables, Lanes roadnetwork) {
    super(id, variables, roadnetwork);
    isHistorical = false;
  }


  /**
   * Observer function that updates values of the dict
   * and transforms (lat, long) to (X, Y) to update the position
   * @param obs Observable from which we are getting the data
   * @param obj Object the Observable is sending
   */
  @Override
    public void update(Observable obs, Object obj) {
    JSONObject payload = (JSONObject)obj;
    String sensorID = payload.getString("dev_id");

    if (sensorID.equals(ID)) {
      JSONObject payloadFields = payload.getJSONObject("payload_fields");
      String[] dictKeys = variablesValues.keyArray();

      for (int i = 0; i < dictKeys.length; i++) {
        float value = payloadFields.getFloat(dictKeys[i]);
        variablesValues.set(dictKeys[i], value);
      }

      if (lastPosition == null) {
        if ((variablesValues.get("lat") != 0) && (variablesValues.get("lon") != 0)) {
          currPosition = lastPosition = roadnetwork.findClosestPoint(roadnetwork.toXY(variablesValues.get("lat"), variablesValues.get("lon")));
        }
      } else {              
        lastPosition = currPosition.copy();
        currPosition = roadnetwork.findClosestPoint(roadnetwork.toXY(variablesValues.get("lat"), variablesValues.get("lon")));
      }
    }
  }


  /**
   * Draw sensor with its properties in a roadnetwork
   * @param canvas  Canvas in which to draw 
   * @param size    Size of the ellipse
   * @param c       Color of the ellipse
   */
  @Override
    public void draw(Canvas canvas, int size) {
    if (lastPosition != null) {
      float temp = variablesValues.get("temp");
      canvas.noStroke();

      if (temp >= 0) canvas.fill(map(temp, -10, 30, 0, 255), map(temp, -10, 30, 0, 255), 0);
      else canvas.fill(0, map(temp, -10, 30, 255, 0), map(temp, -10, 30, 255, 0));

      lastPosition.x = lerp(lastPosition.x, currPosition.x, 0.01);
      lastPosition.y = lerp(lastPosition.y, currPosition.y, 0.01);

      lastPosition = roadnetwork.findClosestPoint(lastPosition);    

      canvas.ellipse(lastPosition.x, lastPosition.y, rad, rad);

      if (decreasing) rad = rad - 0.1;
      if (!decreasing) rad = rad + 0.1;
      if (rad < size) decreasing = false;
      if (rad > 12) decreasing = true;
    }
  }
}


/**
 * Extended object represents a sensor that stores historical values
 * of its gps, temperature and humidity variables
 * @author    Jesús García
 * @version   0.1
 */
public class HistoricalSensor extends Sensor {
  private Table historical = new Table();
  private ArrayList<PVector> positionsXY = new ArrayList<PVector>();


  /**
   * Initiate sensor with parameters that define itself
   * @param id            ID of the lane
   * @param variables     Variables that the sensor is gathering
   * @param roadnetwork   Roads of the zone
   */
  public HistoricalSensor(String id, String[] variables, Lanes roadnetwork) {
    super(id, variables, roadnetwork);
    createTable(variables);
    isHistorical = true;
  }


  /**
   * Initiate table with the keys provided in the constructor and a timestamp
   * @param sensorVariables  String array with all the keys
   */
  private void createTable(String[] sensorVariables) {
    for (int i = 0; i < sensorVariables.length; i++) {
      historical.addColumn(sensorVariables[i]);
    }
    historical.addColumn("timestamp");
  }


  /**
   * Get the table with all the historical entries for the sensor variables
   * @returns Table object with all the stored data
   */
  public Table getEntries() {
    return historical;
  }


  /**
   * Get all the stored positions of the sensor
   * @returns  ArrayList of PVectors with all the (X, Y) positions
   */
  public ArrayList<PVector> getPositions() {
    return positionsXY;
  }


  /**
   * Transforms (lat, lon) coordinates to an (X, Y) position
   * to store it in the positions array
   * @param lat  Latitude coordinate
   * @param lon  Longitude coordinate
   */
  private void toXY(float lat, float lon) {
    if (lat != 0 && lon != 0) {
      PVector position = roadnetwork.findClosestPoint(roadnetwork.toXY(lat, lon));
      positionsXY.add(position);
    }
  }


  /**
   * Observer function that updates values of the table
   * and the positions array
   * @param obs Observable from which we are getting the data
   * @param obj Object the Observable is sending
   */
  @Override
    public void update(Observable obs, Object obj) {
    JSONObject payload = (JSONObject) obj;
    String sensorID = payload.getString("dev_id");

    if (sensorID.equals(ID)) {
      JSONObject metadata = payload.getJSONObject("metadata");
      String time = metadata.getString("time").replace("T", " ").replace("Z", "");

      JSONObject payloadFields = payload.getJSONObject("payload_fields");      
      String[] dictKeys = variablesValues.keyArray();
      TableRow newHistorical = historical.addRow();

      for (int i = 0; i < dictKeys.length; i++) {        
        float value = payloadFields.getFloat(dictKeys[i]);
        newHistorical.setFloat(dictKeys[i], value);
      }
      newHistorical.setString("timestamp", time);

      toXY(payloadFields.getFloat("lat"), payloadFields.getFloat("lon"));
    }
  }


  /**
   * Draw ellipses for every historical entry
   * @param canvas    Canvas in which to draw 
   * @param size      Size of the ellipse
   */
  @Override
    public void draw(Canvas canvas, int size) {
    canvas.strokeWeight(2);
    for (TableRow entry : historical.rows()) {
      canvas.stroke(0, 0, map(entry.getFloat("hum"), 0, 100, 0, 255));

      if (entry.getFloat("temp") >= 0) canvas.fill(map(entry.getFloat("temp"), -10, 30, 0, 255), map(entry.getFloat("temp"), -10, 30, 0, 255), 0);
      else canvas.fill(0, map(entry.getFloat("temp"), -10, 30, 255, 0), map(entry.getFloat("temp"), -10, 30, 255, 0));
    }

    for (int i = 0; i < positionsXY.size(); i++) {
      canvas.ellipse(positionsXY.get(i).x, positionsXY.get(i).y, size, size);
    }
  }
}
