import java.util.Observer;


/**
 * Kind of a facade to create and manage all the sensors
 * @author      Guillem Francisco
 * @modified    Jesús García
 * @version     0.1
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
  public Sensors(String file, MQTTClient client, Lanes roads, WarpSurface surface) {
    roadnetwork = roads;
    load(file, client, surface);
  }


  /**
   * Create sensors Objects from JSON file and add observers to MQTTClient
   * @param file  JSON file direction
   * @param client  MQTTClient in which we will add the observers
   */
  private void load(String file, MQTTClient client, WarpSurface surface) {
    processing.data.JSONObject object = loadJSONObject(file);
    processing.data.JSONArray sensors = object.getJSONArray("sensors");

    for (int i = 0; i < sensors.size(); i++) {
      processing.data.JSONObject sensor = sensors.getJSONObject(i);

      String id = sensor.getString("deviceID");
      String type = sensor.getString("type");
      processing.data.JSONArray variables = sensor.getJSONArray("variables");
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

        surface.addObserver(newSensor);
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


  /**
   * Gets the value of SENSORS
   * @returns ArrayList<Senso>  Array with the stored Sensor instances
   */
  public ArrayList<Sensor> getSensors() {
    return SENSORS;
  }
}


/**
 * Abstract Observer object that represents a generic sensor. It has the specified variables and
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
  private LatLon coordinates;
  private float rad = random(10, 20);
  private boolean decreasing = true;
  private color c;
  private boolean selected;
  private NominatimReverseGeocodingJAPI nominatim1 = new NominatimReverseGeocodingJAPI();
  private ArrayList<Float> recentTemps = new ArrayList<Float>();
  private ArrayList<Float> recentHums = new ArrayList<Float>();
  private ArrayList<String> recentAddrss = new ArrayList<String>();


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
   * Observer function which performs certain updates depending on the Observable that sent the data
   * @param obs Observable from which we are getting the data
   * @param obj Object the Observable is sending
   */
  @Override
    public void update(Observable obs, Object obj) {
    if (obs instanceof MQTTClient) updateValues(obj);
    else select(obj);
  }


  /**
   * Updates values of the dict and transforms (lat, long) to (X, Y) to update the position.
   * Also updates the arrays storing the most recently collected values and the polar coordinates
   * @param obj Object the Observable is sending
   */
  private void updateValues(Object obj) {
    processing.data.JSONObject payload = (processing.data.JSONObject)obj;
    String sensorID = payload.getString("dev_id");

    if (sensorID.equals(ID)) {
      processing.data.JSONObject payloadFields = payload.getJSONObject("payload_fields");
      String[] dictKeys = variablesValues.keyArray();

      for (int i = 0; i < dictKeys.length; i++) {
        float value = payloadFields.getFloat(dictKeys[i]);
        variablesValues.set(dictKeys[i], value);
      }

      if (recentTemps.size() < 3) {
        recentTemps.add(variablesValues.get("temp"));
        recentHums.add(variablesValues.get("hum"));
      } else {
        recentTemps.remove(recentTemps.get(0));
        recentTemps.add(variablesValues.get("temp"));

        recentHums.remove(recentHums.get(0));
        recentHums.add(variablesValues.get("hum"));
      }

      if (lastPosition == null) {
        if ((variablesValues.get("lat") != 0) && (variablesValues.get("lon") != 0)) {
          currPosition = lastPosition = roadnetwork.findClosestPoint(roadnetwork.toXY(variablesValues.get("lat"), variablesValues.get("lon")));
          coordinates = new LatLon(variablesValues.get("lat"), variablesValues.get("lon"));
        }
      } else {
        if (variablesValues.get("temp") >= 0) c = color(map(variablesValues.get("temp"), -10, 30, 0, 255), map(variablesValues.get("temp"), -10, 30, 0, 255), 0);
        else color(0, map(variablesValues.get("temp"), -10, 30, 255, 0), map(variablesValues.get("temp"), -10, 30, 255, 0));

        lastPosition = currPosition.copy();
        currPosition = roadnetwork.findClosestPoint(roadnetwork.toXY(variablesValues.get("lat"), variablesValues.get("lon")));
        coordinates.set(variablesValues.get("lon"), variablesValues.get("lat"));
      }

      if ((payloadFields.getDouble("lat") != 0) && (payloadFields.getDouble("lon") != 0)) {
        String address = nominatim1.getAdress(payloadFields.getDouble("lat"), payloadFields.getDouble("lon")).getDisplayName();
        String postCode = nominatim1.getAdress(payloadFields.getDouble("lat"), payloadFields.getDouble("lon")).getPostcode();
        if (recentAddrss.size() < 3) {
          recentAddrss.add(address.substring(0, address.indexOf(", " + postCode)));
        } else {
          recentAddrss.remove(recentAddrss.get(0));
          recentAddrss.add(address.substring(0, address.indexOf(", " + postCode)));
        }
      }
    }
  }


  /**
   * Updates the value of selected
   * @param obj Object the Observable is sending
   */
  private void select(Object obj) {
    LatLon location = (LatLon) obj;
    if (coordinates != null) selected = (coordinates.dist(location) < 20);
  }


  /**
   * Draw sensor with its properties in a roadnetwork
   * @param canvas  Canvas in which to draw 
   * @param size    Size of the ellipse
   * @param c       Color of the ellipse
   */
  @Override
    public void draw(Canvas canvas, int size) {
    if (lastPosition != null && c != 0) {
      canvas.strokeWeight(2);
      if (selected) {
        canvas.stroke(#D32D41);
      } else canvas.stroke(0);

      canvas.fill(c);

      lastPosition.x = lerp(lastPosition.x, currPosition.x, 0.01);
      lastPosition.y = lerp(lastPosition.y, currPosition.y, 0.01);

      lastPosition = roadnetwork.findClosestPoint(lastPosition);    

      canvas.ellipse(lastPosition.x, lastPosition.y, rad, rad);

      if (decreasing) rad = rad - 0.1;
      if (!decreasing) rad = rad + 0.1;
      if (rad < size) decreasing = false;
      if (rad > 15) decreasing = true;
    }
  }


  /**
   * Creates a line graph from the last 3 collected temperature values 
   * @param canvas  PGraphics object to draw on
   * @param font    PFont object to be used for text
   */
  private void tempDashboard(PGraphics dashboard, PGraphics canvas, PFont font) {
    float lineWidth = (float) 0.8 * canvas.width/(recentTemps.size() - 1);
    canvas.beginDraw();
    canvas.textFont(font);

    canvas.stroke(#555256);
    canvas.strokeWeight(6);
    canvas.fill(0);
    canvas.rect(0, 0, canvas.width, canvas.height);

    canvas.stroke(#AC3E31);
    canvas.strokeWeight(6);
    canvas.line(canvas.width/10, 0.8 * canvas.height, 0.9 * canvas.width, 0.8 * canvas.height);
    canvas.line(canvas.width/10, canvas.height/8, canvas.width/10, 0.8 * canvas.height);

    canvas.stroke(#EA6A47);
    canvas.strokeWeight(4);
    canvas.textSize(0.13 * canvas.height);
    for (int i = 0; i < recentTemps.size() - 1; i++) {
      canvas.pushMatrix();
      canvas.scale(1, -1);
      canvas.translate(0, -canvas.height);
      canvas.ellipse(i * lineWidth + canvas.width/10, map(recentTemps.get(i), -10, 30, canvas.height/8, 0.8 * canvas.height), 0.05 * canvas.width, 0.05 * canvas.width);
      canvas.line(i * lineWidth + canvas.width/10 + 0.05 * canvas.width/2, map(recentTemps.get(i), -10, 30, canvas.height/8, 0.8 * canvas.height), (i+1) * lineWidth + canvas.width/10, 
        map(recentTemps.get(i+1), -10, 30, canvas.height/8, 0.8 * canvas.height));
      canvas.pushStyle();
      canvas.fill(0);
      canvas.ellipse((i+1) * lineWidth + canvas.width/10, map(recentTemps.get(i+1), -10, 30, canvas.height/8, 0.8 * canvas.height), 0.05 * canvas.width, 0.05 * canvas.width);
      canvas.scale(1, -1);
      canvas.fill(255);
      canvas.text(str(recentTemps.get(i)), (i) * lineWidth + canvas.width/10, -(map(recentTemps.get(i), -10, 30, canvas.height/8, 0.8 * canvas.height) + 0.1 * canvas.height));
      canvas.text(str(recentTemps.get(i+1)), (i+1) * lineWidth + canvas.width/10, -(map(recentTemps.get(i+1), -10, 30, canvas.height/8, 0.8 * canvas.height) + 0.1 * canvas.height));
      canvas.popStyle();
      canvas.popMatrix();
    }

    canvas.textSize(0.15 * canvas.height);
    canvas.fill(255);

    canvas.pushStyle();
    canvas.textAlign(CENTER, TOP);
    canvas.text("Time", canvas.width/2, 0.8 * canvas.height);
    canvas.popStyle();

    canvas.pushStyle();
    canvas.textAlign(CENTER);
    canvas.rotate(-HALF_PI);
    canvas.text("TEMP ºC", -canvas.width/5.5, canvas.height/6);
    canvas.popStyle();
    canvas.endDraw();

    dashboard.image(canvas, 0, 0);
  }


  /**
   * Creates a line graph from the last 3 collected humidity values 
   * @param canvas  PGraphics object to draw on
   * @param font    PFont object to be used for text
   */
  private void humDashboard(PGraphics dashboard, PGraphics canvas, PFont font) {
    float lineWidth = (float) 0.8 * canvas.width/(recentHums.size() - 1);
    canvas.beginDraw();
    canvas.textFont(font);

    canvas.stroke(#555256);
    canvas.strokeWeight(6);
    canvas.fill(0);
    canvas.rect(0, 0, canvas.width, canvas.height);

    canvas.stroke(#1C4E80);
    canvas.strokeWeight(8);
    canvas.line(canvas.width/10, 0.8 * canvas.height, 0.9 * canvas.width, 0.8 * canvas.height);
    canvas.line(canvas.width/10, canvas.height/8, canvas.width/10, 0.8 * canvas.height);

    canvas.stroke(#0091D5);
    canvas.strokeWeight(4);
    canvas.textSize(0.13 * canvas.height);
    for (int i = 0; i < recentHums.size() - 1; i++) {
      canvas.pushMatrix();
      canvas.scale(1, -1);
      canvas.translate(0, -canvas.height);
      canvas.ellipse(i * lineWidth + canvas.width/10, map(recentHums.get(i), 0, 100, canvas.height/8, 0.8 * canvas.height), 0.05 * canvas.width, 0.05 * canvas.width);
      canvas.line(i * lineWidth + canvas.width/10 + 0.05 * canvas.width/2, map(recentHums.get(i), 0, 100, canvas.height/8, 0.8 * canvas.height), (i+1) * lineWidth + canvas.width/10, 
        map(recentHums.get(i+1), 0, 100, canvas.height/8, 0.8 * canvas.height));
      canvas.pushStyle();
      canvas.fill(0);
      canvas.ellipse((i+1) * lineWidth + canvas.width/10, map(recentHums.get(i+1), 0, 100, canvas.height/8, 0.8 * canvas.height), 0.05 * canvas.width, 0.05 * canvas.width);
      canvas.scale(1, -1);
      canvas.fill(255);
      canvas.text(str(recentHums.get(i)), (i) * lineWidth + canvas.width/10, -(map(recentHums.get(i), 0, 100, canvas.height/8, 0.8 * canvas.height) + 0.1 * canvas.height));
      canvas.text(str(recentHums.get(i+1)), (i+1) * lineWidth + canvas.width/10, -(map(recentHums.get(i+1), 0, 100, canvas.height/8, 0.8 * canvas.height) + 0.1 * canvas.height));
      canvas.popStyle();
      canvas.popMatrix();
    }

    canvas.textSize(0.15 * canvas.height);
    canvas.fill(255);

    canvas.pushStyle();
    canvas.textAlign(CENTER, TOP);
    canvas.text("Time", canvas.width/2, 0.8 * canvas.height);
    canvas.popStyle();

    canvas.pushStyle();
    canvas.textAlign(CENTER);
    canvas.rotate(-HALF_PI);
    canvas.text("HUM %", -canvas.width/5.5, canvas.height/6);
    canvas.popStyle();
    canvas.endDraw();

    dashboard.image(canvas, dashboard.width * 0.3, 0);
  }


  /**
   * Writes the last 3 addresses where the sensor has been
   * @param canvas  PGraphics object to show the addresses on
   * @param font    PFont object to be used for text
   */
  private void addrssDashboard(PGraphics dashboard, PGraphics canvas, PFont font) {
    canvas.beginDraw();
    canvas.textFont(font);

    canvas.stroke(#555256);
    canvas.strokeWeight(6);
    canvas.fill(0);
    canvas.rect(0, 0, canvas.width, canvas.height);

    canvas.fill(255);
    canvas.textSize(0.09 * canvas.height);
    for (int i = 1; i < recentAddrss.size() + 1; i++) {
      canvas.textAlign(CENTER);
      canvas.text(recentAddrss.get(i-1), canvas.width/2, 0.25 * canvas.height * i + 0.08 * canvas.height);
    }

    canvas.pushStyle();
    canvas.textAlign(CENTER, TOP);
    canvas.textSize(0.15 * canvas.height);
    canvas.text("ADDRESSES", canvas.width/2, 0);
    canvas.popStyle();
    canvas.endDraw();

    dashboard.image(canvas, dashboard.width * 0.6, 0);
  }


  /**
   * Shows the 3 dashboards together
   * @param dashboard      PGraphics object to show all the dashboards
   * @param canvasTemp     PGraphics object to draw the temperature line graph
   * @param canvasHum      PGraphics object to draw the humidity line graph
   * @param canvasAddrss   PGraphics object to write down the addresses
   * @param font           PFont to be used when writing
   */
  public void drawDashboard(PGraphics dashboard, PGraphics canvasTemp, PGraphics canvasHum, PGraphics canvasAddrss, PFont font) {
    if (selected) {
      tempDashboard(dashboard, canvasTemp, font);
      humDashboard(dashboard, canvasHum, font);
      addrssDashboard(dashboard, canvasAddrss, font);
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
    processing.data.JSONObject payload = (processing.data.JSONObject) obj;
    String sensorID = payload.getString("dev_id");

    if (sensorID.equals(ID)) {
      processing.data.JSONObject metadata = payload.getJSONObject("metadata");
      String time = metadata.getString("time").replace("T", " ").replace("Z", "");

      processing.data.JSONObject payloadFields = payload.getJSONObject("payload_fields");      
      String[] dictKeys = variablesValues.keyArray();
      TableRow newHistorical = historical.addRow();

      for (int i = 0; i < dictKeys.length; i++) {        
        float value = payloadFields.getFloat(dictKeys[i]);
        newHistorical.setFloat(dictKeys[i], value);
      }

      newHistorical.setString("timestamp", time);

      if (payloadFields.getFloat("lat") != 0 && payloadFields.getFloat("lon") != 0) {
        toXY(payloadFields.getFloat("lat"), payloadFields.getFloat("lon"));
      }
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
